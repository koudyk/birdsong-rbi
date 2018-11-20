% 2018.09.19 see the pitch curves for the stimuli and imitations, and
% hear the audio


% INSTRUCTIONS: PRESS ENTER WHEN YOU'RE IN THE FIGURE WINDOW IN ORDER
% TO PROCEED TO THE NEXT FILE, BUT WAIT UNTIL THE
% AUDIO IS FINISHED. IF YOU DON'T WANT TO HEAR THE AUDIO, SET soundON
% to 0

% NOTE: THE TOP FIGURE WILL HAVE WHITE SPACE AT THE END BECAUSE THE
% PARTICIPANTS WERE GIVEN 2 SECONDS LONGER THAN THE LENGTH OF THE
% STIMULUS TO DO THEIR IMITATION


% SET PATHS TO YOUR COMPUTER
clc;clear;close all; clear sound
dir_data = BVI_path();
cd(dir_data)

list_participantFiles = dir('imitations_participant*'); % list of participant files
Nparticipant = length(list_participantFiles); % total number of participants
fs = 44100; % audio sampling rate (the same for all audio)
soundOn = 1; % set to 0 if you don't want to hear the audio

for nparticipant = 2:3
    load(list_participantFiles(nparticipant).name) % loads structure called "imitations"
    
    Nimitation = length(imitations);
    for nimitation = 90
        fprintf('Participant %d; imitation %d \n',nparticipant,nimitation)
        fig_comparePCs(imitations,nimitation,soundOn)
        %pause % pauses until you press "enter" while you're in the figure window
        clear sound
    end
    %pause
end

for nparticipant = 2:3
    load(list_participantFiles(nparticipant).name) % loads structure called "imitations"
    
    Nimitation = length(imitations);
    for nimitation = 93
        fprintf('Participant %d; imitation %d \n',nparticipant,nimitation)
        fig_comparePCs(imitations,nimitation,soundOn)
        %pause % pauses until you press "enter" while you're in the figure window
        clear sound
    end
    %pause
end


close all

%%
n = 90;
a = imitations(n).stimulusAudio;
audiowrite('example_veery.wav',a,44100)

%%
clear sound
fs=44100;
n = 93;
a = imitations(n).stimulusAudio;
audiowrite('example_white-throated-sparrow.wav',a,44100)
sound(a,fs)
