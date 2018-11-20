clc,clear%,close all, clear sound
laptop='C:\Users\User\Documents\MATLAB\Projects\birdsongQBH';
exhard='F:\0.birdsongQBH\audio'; %external harddrive
addpath(genpath(exhard))
addpath(genpath(laptop))
cd(exhard)
list_segs=dir('audio_cleanExcerpts*');
Nspec=length(list_segs);
fs=44100;
NperSpec=10;
%%
%stimuli=cell(Nspec*NperSpec);

c=0;
for nspec=1:Nspec
    load(list_segs(nspec).name)
    
    NXC=length(audio_excerpts);
    excerpts(nspec).stimulus = 0;
    randXC = randperm(NXC);
    for nXC = randXC(1:10) % choose random XC ID
        excerpts(nspec).stimlus = c; % indicates that it is used as a stimlus and which number
        c=c+1;disp(c)
        [~,i_longest]=max(cellfun('length',audio_excerpts{nXC})); % choose longest excerpt
        a=audio_excerpts{nXC}{i_longest};
        
        stimuli(c).no = c;
        stimuli(c).spec = nspec;
        stimuli(c).xcID = xcID(nXC);
        stimuli(c).nxcID = nXC;
        stimuli(c).excerpt = i_longest;
        stimuli(c).fs = fs;
        stimuli(c).stimulus = a; 
%         sound(stimuli(c).stimulus,fs)
%         pause(length(stimuli(c).stimulus)/fs +.25)
    end
    save(list_segs(nspec).name,'excerpts','-v7.3')
end

save('STIMULI4','stimuli')
%%

% load('STIMULI3')
% for c=1:100;
%     disp(c)
%         sound(stimuli(c).stimulus,fs)
%         pause(length(stimuli(c).stimulus)/fs +.25)
% end


% for nspec=1:Nspec
%     load(list_segs(nspec).name)
%     nperSpec=0;
%     for nXC=1:NperSpec
%         [~,i_longest]=max(cellfun('length',audio_segs{nXC}));
%         a=audio_segs{nXC}{i_longest};
%         stimuli{nspec,nXC}=a;
%         sound(a,fs)
%         pause(length(a)/fs + .25)
%     end
%     
% end