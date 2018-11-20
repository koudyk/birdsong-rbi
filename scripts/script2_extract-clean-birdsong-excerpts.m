% extract "clean" excerpts from the Xeno Canto files using the
% annotations made manually in Sonic Visualizer

clc,clear,close all, clear sound
laptop='C:\Users\User\Documents\MATLAB\Projects\birdsongQBH';
exhard='F:\0.birdsongQBH\audio'; %external harddrive
addpath(genpath(exhard))
addpath(genpath(laptop))

cd(fullfile(exhard,'excerptAnnotations'))
list_anno_total=dir('spc*.txt'); % list of all annotations
Nanno=length(list_anno_total); % number of annotations
minLen = 882; % in frames - minimum length (to avoid extracting erroneous too-short excerpts)
Nspec = 10; % number of species

c = 0; % counter of all excerpts
for nspec=1:Nspec
    cd(fullfile(exhard,'excerptAnnotations'))
    disp(sprintf('-------------- spc %d --------------',nspec))
    clear excerpts
    list_anno=dir(sprintf('spc%02d*.txt',nspec));
    
    %n = find([list_anno.name]==
    
    NxcID = length(list_anno);
    ne=0;
    for nxcID=1:NxcID
        disp(nxcID)
        [x,fs]=audioread([list_anno(nxcID).name(1:end-4) '.wav']);
        x=mean(x,2);
        
        % normalize volume - code from Vincent
        x_centered = x - mean(x);
        power = norm(x_centered) / length(x_centered);
        x_normalized = x_centered / power;

        [segs, locs] = extractAudioExcerpts(x,list_anno(nxcID).name,0,fs);
        Nexcerpt = length(segs);
        for nexcerpt = 1:Nexcerpt
            excerpt=segs{nexcerpt};
            if length(excerpt) > minLen
                ne=ne+1;
                c = c+1;
                excerpts(ne).species = nspec;
                excerpts(ne).xcID = str2double(list_anno(nxcID).name(9:end-4));
                excerpts(ne).excerptNumInXCfile = nexcerpt;
                excerpts(ne).begEndExcerpt_frames = locs(nexcerpt,:);
                excerpts(ne).excerptID = c;
                excerpts(ne).audio = segs{nexcerpt};
            end
      
        end
    end
    cd(exhard)
     file=sprintf('excerpts_audioExcerpts_species%02d',nspec);
     save(file,'excerpts','fs','-v7.3')
end

