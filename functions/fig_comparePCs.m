function fig_comparePCs(imitations,nimitation,soundOn, par)
% visualize the stimulus and query spectrograms with the estimated
% pitch curves overlayed
%
% INPUT
% imitations - structure containing the audio from the imitations of one
%               participant
% nimitation  - imitation number 
% soundOn    - 1 if you want to hear the sound; 0 if you don't

clf

if nargin < 3, soundOn = 0; end
if nargin < 4 , load('BirdVox-imitation_default-parameters.mat'), end
 load('BirdVox-imitation_species-names.mat')

%fref_hz = 440;
fs = imitations(nimitation).fs;
audio_stimulus = imitations(nimitation).stimulusAudio;
audio_imitation = imitations(nimitation).imitationAudio;
nspecies = imitations(nimitation).species;
font = 14;

ax1 = subplot(211);
[~,~,~,fig] = yb_yinbird(audio_stimulus,par);
title('Stimulus (birdsong excerpt)')
set(gca,'fontsize',font)
set(gca,'yticklabels',[])
set(gca,'xticklabels',[])

ax2 = subplot(212);
[~,fig] = yin_imitations(audio_imitation,par);
title('Imitation')
set(gca,'fontsize',font)
linkaxes([ax2 ax1],'x')
set(gca,'yticklabels',[])
set(gca,'xticklabels',[])

dim = [.01 .1 .9 .9];
str = list_speciesNames{nspecies};
%annotation('textbox',dim,'String',str,'FitBoxToText','on');

if soundOn==1
    length_stimulus = length(audio_stimulus)/fs;
    sound(audio_stimulus,fs)
    pause(length_stimulus)

    length_imitation = length(audio_imitation)/fs;
    sound(audio_imitation,fs)
    pause(length_imitation)
    
end
    
    
end