function [ pitchCurve_oct,T,r,fig_yb,fig_ybVy]  =  yb_yinbird( audio,par)
%	YB_YINBIRD calculates the pitch curve for birdsong, 
%   implementing YIN-bird (O'Reilley & Harte, 2017).	
%	
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
%
% OUTPUTS
%   pitchCurve_oct - YINbird pitch curve, in octaves over time in hops
%	f0_yb     - (Hz) f-by-1 vector of fundamental-frequency 
%               values (f0) estimated with YIN-bird.
%	T         - (sec) t-by-1 vector of time values for the pitch curve.
%   r         - output structure of the YIN function. The current
%               function adds the following outputs to this structure:
%               r.f0yinbird       - the YINbird pitch curve, in octaves
%               r.timescale_sec   - timescale for the pitch curve, in seconds
%               r.minf0_hz        - minimum f0 curve, in Hz over time in hops
%               r.Fprom_hz        - prominent-frequency curve, in Hz over
%                                 time in hops
%               r.f0_hz           - the YIN (not YINbird) pitch curve, in Hz
%               r.f0yinbird_hz    - the YINbird pitch curve, in Hz
%	fig_yb    - outputs a figure with the pitch curve and the 
%               minimum-frequency curve overlayed over the spectrogram 
%               for the given file.
%	fig_ybVy  - outputs a figure with 2 subplots for comparing YIN to
%               YINbird.  


if nargin<2, par.fs = 44100; end

if ischar(audio), [a,par.fs] = audioread(audio);
else a = audio;
end
a=mean(a,2);

temp = load('BirdVox-imitation_default-parameters.mat');

if ~isfield(par,'fs'),         par.fs = temp.par.fs; end
fs = par.fs;
if ~isfield(par,'wsize_sec'),  par.wsize_sec = temp.par.wsize_sec; end
wsize_sec = par.wsize_sec;
if ~isfield(par,'hop_pwin'),   par.hop_pwin = temp.par.hop_pwin; end
hop_pwin = par.hop_pwin;
if ~isfield(par,'aperThresh'), par.aperThresh = temp.par.aperThresh; end
aperThresh = par.aperThresh;
if ~isfield(par,'ssize_sec'),  par.ssize_sec = temp.par.ssize_sec; end
ssize_sec = par.ssize_sec;
if ~isfield(par,'fmin_hz'),    par.fmin_hz = temp.par.fmin_hz; end
fmin_hz = par.fmin_hz;
if ~isfield(par,'fmax_hz'),    par.fmax_hz = temp.par.fmax_hz; end
fmax_hz = par.fmax_hz;
if isfield(par,'yinPar'),      p=par.yinPar; end

% adding parameters to the input structure for YIN (p)
p.sr = fs;
p.maxf0 = fmax_hz;

wsize_samp = floor(fs*wsize_sec); p.wsize = wsize_samp;% samples; window size
hop_samp = floor(wsize_samp*hop_pwin); p.hop = hop_samp; % samples; hop
hop_sec = hop_samp/fs;
ssize_hop = floor((1/hop_sec)*ssize_sec);
fref_hz = 440; % Hz; reference frequency used by YIN to put the pitch curve in octaves
overlap_samp=wsize_samp-hop_samp;

% SPECTROGRAM
[~,F,T,P] = spectrogram(a,wsize_samp,overlap_samp,[],fs);

% MINIMUM-FREQUENCY CURVE FOR YIN
[minf0_hop,minf0_seg,~,Fprom_hop]  =  yb_minf0( a,par );

% CALCULATE PITCH CURVE FOR EACH UNIQUE MINIMUM FREQUENCY
Uminf0 = unique(minf0_hop); % Hz; unique minimum frequencies
%f0s = zeros(length(Uminf0),length(minf0_hop));
for nUminf0 = 1:length(Uminf0) % number of unique min freq, i.e., number of times YIN must be run    
    p.minf0 = Uminf0(nUminf0); % Hz; set minumum frequency for  YIN
    r_temp = yin(audio,p);
    f0 = r_temp.f0;
    f0(r_temp.ap0 > aperThresh) = nan;
    f0s(nUminf0,:) = f0;
end

% PIECE TOGETHER FINAL PITCH CURVE USING THE PITCH CURVE THAT WAS GENERATED WITH THE SEGMENT'S MIN F0 
pitchCurve_oct = [];
Nseg = floor(length(minf0_hop)/ssize_hop); % total number of segments that fit into the prominent-frequency curve     
for nseg = 1:Nseg
    minf0 = minf0_seg(nseg);
    i_Uminf0 = find(Uminf0 == minf0); % index in unique min f0s of the current min f0 - for finding which f0 curve to use for this segment
    f0 = f0s(i_Uminf0,:); % pitch curve that was calculated with the desired min f0
    beg = nseg * ssize_hop - ssize_hop + 1;
    seg = f0(beg : beg + ssize_hop - 1);
    pitchCurve_oct = [pitchCurve_oct seg];
end
pitchCurve_oct(end:length(r_temp.f0)) = f0s(i_Uminf0,length(pitchCurve_oct:length(T))); % use the minimum f0 from the last full segment to calculate the pitch curve for the portion of the file that doesn't fill a segment

%f0yb_hz = f0yb_hz(1:length(minf0_hop)); % there's an NaN at the end %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%not sure why or if this is the right way to deal with it %%%%%%%%%%%%

% PLAIN YIN
p.minf0 = fmin_hz;    
r = yin_k(a,p);

% make yin and spectrogram output the same length
T = [nan T]; % add preceeding NaN (becasue it seems that there's always a NaN at the beginning of YIN's pitch curve)
minf0_hop = [nan minf0_hop];
Fprom_hop = [nan Fprom_hop'];

T(end+1:length(r.f0)) = NaN; % if needed, add trailing NaNs
minf0_hop(end+1:length(r.f0)) = NaN;
Fprom_hop(end+1:length(r.f0)) = NaN;

% ADD YINBIRD OUTPUTS TO YIN'S 'r' OUTPUT
r.f0yinbird = pitchCurve_oct;
r.timescale_sec = T;
r.minf0_hz = minf0_hop;
r.Fprom_hz = Fprom_hop;

% CONVERT OUTPUT TO FREQUENCY (HZ) INSTEAD OF OCTAVES
r.f0_hz  =  2.^ r.f0 .*fref_hz; 
r.f0yinbird_hz = 2.^ r.f0yinbird .*fref_hz;

if nargout > 3  % if they want a plot
    fmax_hz_plot = min([fmax_hz max(r.f0yinbird_hz)+1000]);
    fmin_hz_plot = max([fmin_hz min(r.f0yinbird_hz)-1000]);
    [~,fmax_i] = min(abs(F-fmax_hz_plot));
    [~,fmin_i] = min(abs(F-fmin_hz_plot));
    P = P(fmin_i:fmax_i,:);
end

if nargout==4 % plot YIN-bird pitch curve
    fig_yb = 1;
    %fig_yb=figure;
    imagesc([0 max(T)],[fmin_hz_plot,fmax_hz_plot],10*log10(P));
    set(gca(),'Ydir','normal')
    hold on, plot(T,r.minf0_hz,'w')
    hold on, plot(T,r.f0yinbird_hz,'r-','linewidth',1.5)
    legend('Minimum frequency for YIN','YIN-bird pitch estimate')
    title('YIN-bird') 
    ylabel('Frequency (Hz)'), xlabel('Time (sec)')
end

if nargout == 5 % plot yin and yin bird 
    fig_ybVy=1; fig_yb=fig_ybVy;
    %fig_ybVy=figure; fig_yb=fig_ybVy;
    subplot(2,1,1)
    imagesc([0 max(T)],[fmin_hz_plot,fmax_hz_plot],10*log10(P));
    set(gca(),'Ydir','normal')

    yf0 = r.f0_hz;
    yf0(r_temp.ap0 > aperThresh) = nan;
    
    hold on, plot(T,yf0,'r-', 'linewidth',1.5)
    title('YIN')
    ylabel('Frequency (Hz)'), xlabel('Time (sec)')
    
    subplot(2,1,2);
    imagesc([0 max(T)],[fmin_hz_plot,fmax_hz_plot],10*log10(P));
    set(gca(),'Ydir','normal')
    hold on, plot(T,r.minf0_hz,'w')
    hold on, plot(T,r.f0yinbird_hz,'r-','linewidth',1.5)
    title('YIN-bird')
    ylabel('Frequency (Hz)'), xlabel('Time (sec)')
end
end
