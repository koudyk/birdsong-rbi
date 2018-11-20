function fig_comparePCs(imitations,nimitation,stimulus_imitation,soundOn, par)
% visualize the stimulus and query spectrograms with the estimated
% pitch curves overlayed
%
% INPUT
% imitations - structure containing the audio from the imitations of one
%               participant
% nimitation  - imitation number 
% stimulus_imitation - 1 for stimulus; 2 for imitation
% soundOn    - 1 if you want to hear the sound; 0 if you don't

clf

if nargin < 4, soundOn = 0; end
if nargin < 5 , load('BirdVox-imitation_default-parameters.mat'), end
 load('BirdVox-imitation_species-names.mat')
 

%fref_hz = 440;
fs = imitations(nimitation).fs;

nspecies = imitations(nimitation).species;

if stimulus_imitation == 1
    audio = imitations(nimitation).stimulusAudio;
    [~,~,~,fig] = yb_yinbird(audio,par);
    title('Stimulus (birdsong excerpt)')
else
    audio = imitations(nimitation).imitationAudio;
    [~,fig] = yin_imitations(audio,par);
    title('Imitation')
end
set(gca,'yticklabels',[])
set(gca,'xticklabels',[])
ylabel([])
xlabel([])
title([])

dim = [.01 .1 .9 .9];
str = list_speciesNames{nspecies};
%annotation('textbox',dim,'String',str,'FitBoxToText','on');


if soundOn==1
    length_audio = length(audio)/fs;
    sound(audio,fs)
    pause(length_audio)  
end
    
    
end