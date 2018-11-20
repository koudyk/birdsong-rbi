function [ pitchCurve_cents, fig ] = yin_imitations( audio,par )
%yin_queries - calculating the pitch curve for the queries using YIN
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
%         par.aperThresh- aperiodicity threshold (default .1);
%         par.ssize_sec - size of the segments in which to calculate
%                         the minimum f0 for YIN,in seconds (default 
%                         .068 sec, as in the original YINbird paper)
%         par.fmin_hz   - minimum frequency, in Hz (default 30 Hz);
%         par.fmax_hz   - maximum frequency, in Hz (default 10000 Hz)
%         par.yinPar    - other parameters specific to the YIN
%                         function
%
% OUTPUTS
%   pitchCurve_cents - pitch curve, in cents
%   fig - visualize results
    
if ~isfield(par,'fs'),         par.fs = 44100; end,         
if ~isfield(par,'wsize_sec'),  par.wsize_sec = .02; end,    
if ~isfield(par,'hop_pwin'),   par.hop_pwin = .1; end,      
if ~isfield(par,'aperThresh'), par.aperThresh = .1; end,    
if ~isfield(par,'fmin_hz'),    par.fmin_hz = 30; end,       
if ~isfield(par,'fmax_hz'),    par.fmax_hz = .1; end,       
if isfield(par,'yinPar'),      p=par.yinPar; end

wsize_samp = floor(par.fs*par.wsize_sec);
hop_samp = floor(wsize_samp*par.hop_pwin); 

p.sr = par.fs;
p.maxf0 = par.fmax_hz;
p.minf0 = par.fmin_hz;
p.wsize = wsize_samp;% samples; window size
p.hop = hop_samp; % samples; hop

centsPerOctave = 1200;    
    
r = yin(audio,p);
pitchCurve_cents = r.f0 * centsPerOctave;
pitchCurve_cents(r.ap0 > par.aperThresh) = nan;

if nargout > 1, fig = [];
    overlap_samp=wsize_samp-hop_samp;
    fref_hz = 440;
    pc_hz = 2.^ (pitchCurve_cents/centsPerOctave) .*fref_hz; 
    [~,F,T,P] = spectrogram(audio,wsize_samp,overlap_samp,[],par.fs);
    
    extra = length(pc_hz) - length(T);
    step = T(2) - T(1);
    len = length(T);
    for n = 1:extra
        T(len+n) = T(len) + step*n;
    end
    
    fmax_hz_plot = min([par.fmax_hz max(pc_hz)+1000]);
    fmin_hz_plot = max([par.fmin_hz min(pc_hz)-1000]);
    [~,fmax_i] = min(abs(F-fmax_hz_plot));
    [~,fmin_i] = min(abs(F-fmin_hz_plot));
    P = P(fmin_i:fmax_i,:);
    
    imagesc([0 max(T)],[fmin_hz_plot,fmax_hz_plot],10*log10(P));
    set(gca(),'Ydir','normal')
    hold on, plot(T,pc_hz,'r-','linewidth',1.5)
    %legend('YIN pitch estimate')
    %title('YIN') 
    %ylabel('Frequency (Hz)'), xlabel('Time (sec)')
end

end

