function fig_spectrogram(audio,par)
% fig_spect - creates a spectrogram that's oriented correctly and has
% axis labels. This function is handy for quick visualizations
    
if ischar(audio), [a,par.fs] = audioread(audio);
else a = audio;
end
a=mean(a,2);
if nargin<2, load('parameters.mat'), end

    wsize_samp = floor(par.wsize_sec*par.fs);
    hop_samp = floor(par.hop_pwin*wsize_samp);
    overlap_samp = wsize_samp-hop_samp;
    [~,F,T,P] = spectrogram(a,wsize_samp,overlap_samp,[],par.fs);
    [~,fmax_i] = min(abs(F-par.fmax_hz));
    [~,fmin_i] = min(abs(F-par.fmin_hz));
    P = P(fmin_i:fmax_i,:);

    imagesc([0 max(T)],[par.fmin_hz,par.fmax_hz],10*log10(P));
    set(gca(),'Ydir','normal')
    ylabel('Frequency (Hz)'), xlabel('Time (sec)')
    
end