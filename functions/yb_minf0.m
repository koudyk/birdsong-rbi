function [ minf0_hop, minf0_seg,T_minf0_seg,Fprom_hop] = yb_minf0( audio,par )
%	YB_MINF0 calculates the minimum-frequency curve for dynamically 
%   setting the minimum frequency of YIN in YIN-bird.			
%				
% OUTPUTS (variable - (units) description)			
%	minf0_hop  - (hops, i.e., spectrogram time values)	
%                f-by-1 vector of minimum frequencies 
%   minf0_seg  - (segments) s-by-1 vector of minimum frequencies 
%   T_minf0_seg- (sec) s-by-1 vector of time values corresponding to
%                 segments.
%	Fprom_hop  - (hops, i.e., spectrogram time values) 	
%                f-by-1 vector of prominent frequencies 
%                (i.e., the maximum frequency for each window, 
%                with maximum frequencies set to NaN if they 
%                are below the mean maximum frequency across time). 
%				
% INPUTS			
%	audio     -  audio file (in a format readable by the audioread 
%                funciton) or audio waveform (in which case you must 
%                input the sampling rate fs in par.fs)
%   par       -  parameters
%         par.fs        - sampling rate of the audio (default 44100
%                         frames/sec)
%         par.wsize_sec - window size for the spectrogram, in seconds 
%                         (default .02 sec)
%         par.hop_pwin  - hop size, in proportion of the window 
%                         (between 0-1) (default .1, 1/10th of the 
%                         window size)
%         par.ssize_sec - size of the segments in which to calculate
%                         the minimum f0 for YIN,in seconds (default 
%                         .068 sec, as in the original YINbird paper)
%         par.fmin_hz   - minimum frequency, in Hz (default 30 Hz);
%         par.fmax_hz   - maximum frequency, in Hz (default 10000 Hz)


if nargin<2, par.fs = 44100; end
    
if ischar(audio), [a,par.fs] = audioread(audio);
else a = audio;
end
a=mean(a,2);

if ~isfield(par,'fs'),         par.fs = 44100; end,         fs = par.fs;
if ~isfield(par,'wsize_sec'),  par.wsize_sec = .02; end,    wsize_sec = par.wsize_sec;
if ~isfield(par,'hop_pwin'),   par.hop_pwin = .1; end,      hop_pwin = par.hop_pwin;
if ~isfield(par,'ssize_sec'),  par.ssize_sec = .068; end,   ssize_sec = par.ssize_sec;

%     
% PROMINENT-FREQUENCY CURVE
    %[Psp,Fsp,Tsp]=yb_spectrogram(audio,fs,fmin_hz,fmax_hz,wsize_sec,hop_pwin );
    wsize_samp=floor(wsize_sec*fs);
    hop_samp=floor(wsize_samp*hop_pwin);
    overlap_samp=wsize_samp-hop_samp;
    [~,F,T,P] = spectrogram(a,wsize_samp,overlap_samp,[],fs);
    hop_sec=T(2)-T(1); % sec; spectrogram hop size (i.e., seconds to one time value in spectrogram)
    %hop_sec = hop_samp/fs;
    %hop_samples=floor(hop_sec*fs); % audio samples; spectrogram hop size (i.e., audio samples to one time value in spectrogram)
    fs_sp_hops=1/hop_sec; % spectrogram sampling rate in hops
    [Pprom,i]=nanmax(P);
    Fprom_hop=F(i);
    Pprom(Pprom<0)=NaN; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Fprom_hop(Pprom<(nanmean(Pprom)-std(Pprom,'omitnan')))=NaN;  
    Fprom_hop(Pprom<(nanmean(Pprom)))=NaN; 
    
% MINIMUM PROMINENT FREQUENCY FOR EACH SEGMENT
    ssize_hops=floor(fs_sp_hops*ssize_sec); % hops (i.e, spectrogram time points); segment size
    Nseg=floor(length(Fprom_hop)/ssize_hops); % total number of segments that fit into the prominent-frequency curve     
    for nseg=1:Nseg
        beg=nseg*ssize_hops-ssize_hops+1;
        seg=Fprom_hop(beg:beg+ssize_hops-1);
        if nansum(seg)>0
             minf0_seg(nseg)=nanmin(seg);
        else minf0_seg(nseg)=0;
        end
        T_minf0_seg(nseg)=beg;
    end
    minf0_seg=floor(minf0_seg/100)*100; % round to nearest 100 Hz
    minf0_seg(minf0_seg<0)=0;
    
% SET SEGEMENTS WITHOUT A FPROM CURVE TO THE VALUE OF THE NEAREST-NEIGHBOURING SEGMENT (PREFERRING LEFT) 
    nonZero=find(minf0_seg>0);
    if ~isempty(nonZero)
        for nseg=1:Nseg
            if minf0_seg(nseg)==0;
                dif=abs(nonZero-nseg);
                [~,nn]=min(dif); % nearest neighbour
                minf0_seg(nseg)=minf0_seg(nonZero(nn));
            end
        end 
    else minf0_seg(1:Nseg)=zeros;
    end
    
% CONVERT TO NEAREST (LOWEST) POSSIBLE MIN FREQUENCY FOR YIN
    % explanation: YIN sets the minimum frequency in the lag domain,
    % and the rounded lag values include a range of frequencies.
    % (see line 47 the 'yink' function in the 'private' folder of  
    % yin to see where this is done by yin).
    maxLag_seg=ceil(fs./minf0_seg);
    minf0_seg=fs./maxLag_seg;
    
% SET IN HOPS FOR VISUALIZATION WITH THE PITCH CURVE    
    minf0_hop=repelem(minf0_seg,ssize_hops);
    
% designate the minf0 of the last portion of the signal that does
% not fill a full segment as the value of the last full segment
    minf0_hop(end:length(T))=minf0_hop(end); 
end

