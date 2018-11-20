function [meta] = downloadXC(wgetDir,dwnldDir,basic,basicSearchIDs,advanced,...
    targetFs,maxQuantity,start)

%downloadXC 
% Downloads audio from Xeno-Canto.com for given search parameters
% NOTE: this function requires the 'wget' function used by the
% Windows Command Prompt to download the contents of a webpage. I
% created this function to work with Windows 7 and Matlab 2016a. I'm
% not sure if it'll work on different operating systems or Matlab
% versions.
%
% INPUTS
% wgetDir = directory with the wget.exe file
% dwnldDir = directory where the audio will be downloaded to
% basic = cell array of basic queries (one query per cell).
        % A separate search will be run for each cell. 
        % Can be anything allowed in the 'Basic Queries' section of 
        % https://www.xeno-canto.org/help/search
        % e.g., {'black-capped chickadee' 'tinamus' 'Geothlypis trichas'}
% nums = vector of numerical identifiers for each basic search
        % e.g., [44 22 4]
        % By default, the basic searches will be numbered in the order
        % they appear, as in [1 2 3]
% advanced = cell array of advanced query fields (one term per cell).
        % These search parameters will be applied to all basic
        % searches (e.g., all species in 'basic'). 
% targetFs = desired audio sampling rate - the audio will be resampled
        % to this rate if it is not already at this rate
% maxQuantity = maximum number of recordings to be downloaded per
        % basic search
%        
% OUTPUTS
% meta.recordings = field of the metadata structure with information from the JSON from the
    % Xeno Canto search, as well as additional information scraped
    % from the HTML page for the given recording
% meta.species = field of the metadata structure with info about all recordings for
    % each species
% 
% FIELDS WITHIN THE METADATA OUTPUT
% meta.species = information about all the recordings for the given species
% meta.species.num_dwnld = number of audio files downloaded
% meta.species.total_time_sec = (sec) total time of downloaded audio
% meta.species.noDwnld_bkgdBirds = number of files not downloaded due
    % to presence of background species in the recording indicated on
    % the recording's webpage.
% meta.species.noDwnld_error = number of files not downloaded due to
    % a download error
% meta.species.noDwnld_overMaxQuanity = number of files that were not 
    % downloaded because the desired maximum quantity had already 
    % beenreachemeta.
%    
%    
% meta.recordings = information about each recording
% meta.recordings.id = ID number from Xeno Canto
% meta.recordings.gen = genus
% meta.recordings.sp = species
% meta.recordings.ssp = subspecies
% meta.recordings.en = English name
% meta.recordings.rec = recordist
% meta.recordings.cnt = country
% meta.recordings.loc = location
% meta.recordings.lat = latitude
% meta.recordings.lng = longitude
% meta.recordings.type = vocalization type (e.g., song, call)
% meta.recordings.file = URL to the audio file
% meta.recordings.lic = URL to the license website
% meta.recordings.url = URL to the recording's Xeno Canto webpage
% meta.recordings.q = recording quality, ranging from A (highest 
    % quality) to E (lowest quality)
% meta.recordings.time = time of day when the recording was taken
% meta.recordings.date = date of recording
% meta.recordings.bkgd = 1 if the recording's webpage indicated the
    % presence of background species in the recording (not downloaded)
% meta.recordings.dwnld = 1 if successfully downloaded
% meta.recordings.originalFs = original sampling rate of the recording
% meta.recordings.currentFs = sampling rate of the downloaded audio
    % (resampled if the original sampling rate was not the target sampling
    % rate)
%
% created by Kendra Oudyk 05.2018 
% email kendra.oudyk@gmail.com with bugs

%try


if nargin<8 || isempty(start), start = 1; end
if nargin<7 || isempty(targetFs), targetFs=44100; end
if nargin<6 || isempty(basicSearchIDs), basicSearchIDs = 1:length(basic); end
if nargin<5 || isempty(maxQuantity), maxQuantity=Inf; end
%if nargin<5 || isempty(minQuantity), minQuantity=1; end


Nbasic=length(basic);
cd(wgetDir)
weboptions('Timeout',60); % (sec) set web timeout to longer time

% strings to search for in the html for the given recording's webpage
noBkgdSp='Background</td><td valign=''top''>none'; % if there are no background species in the recording, this string will be found in the html of the given recording's webpage
fsBefore='<tr><td>Sampling rate</td><td>'; % text before the sampling rate in the html of the given recording's webpage
fsAfter=' (Hz)</td></tr>'; % text after the sampling rate in the html of the given recording's webpage
birdSeen= 'bird-seen:yes'; 
noPlayback='playback-used:no';

for nbasic=1:Nbasic;
    basic_split = strsplit(basic{nbasic}); 
    basic_joined = strjoin(basic_split,'_');

% MAKE SEARCH FOLDER (i.e., one folder for each cell in 'basic')
    folder=sprintf('search%02d_%s_%s', basicSearchIDs(nbasic), ...
        basic_joined, datestr(now,'yyyy-mm-dd'));  
    mkdir(dwnldDir, folder)  % folder for audio from given species
    
% GET JSON FOR THE GIVEN SEARCH
    URL_json=['https://www.xeno-canto.org/api/2/recordings?query='... % URL for the json of the list of recordings
        strjoin([basic_split advanced],'%20')];
    i=webread(URL_json); 
    %%%%%%%%%%%%%  make doable for <, >, or ==
    if sum(cell2mat(strfind(advanced,'q>:'))) >0 % if they have a minimum quality specification
        i.recordings(cellfun('isempty',strfind({i.recordings.q},'no score'))==0)=[]; % exclude recordings with no quality rating
    end
    listSpecies = unique({i.recordings.en}); % list of unique speices

% (INITIALIZE VARIABLES)
    Nrec=length(i.recordings);
    Ndwnld=min([Nrec maxQuantity]); % set the total number of downloads
    ndwnld=1;
    for nrec=start:Nrec
        fprintf('--------------species %d/%d - recording %d/%d, download %d/%d ------------', ...
            nbasic,Nbasic,   nrec,Nrec,   ndwnld,Ndwnld)
        % species ID
        temp = strfind(listSpecies,i.recordings(nrec).en);
        locs = cellfun('isempty',temp);
        i.recordings(nrec).speciesID = find(locs ==0);
        
        i.recordings(nrec).id=str2double(i.recordings(nrec).id); % change id from a string to a number
        i.recordings(nrec).nbasicSearch=basicSearchIDs(nbasic);
 %       i.recordings(nrec).bkgd=0;
        i.recordings(nrec).dwnld=0;
        
        if ndwnld<=Ndwnld % if it isn't over the desired number of files
            
% DOWNLOAD HTML OF GIVEN RECORDING'S WEBPAGE            
            html=webread(i.recordings(nrec).url); % download html

% CHECK HHTML FOR INICATIONS OF BACKGROUND SPECIES, WHETHER BIRD WAS SEEN, AND
% WHETHER PLAYBACK WAS USED
            no_go(1).x = strfind(html,noBkgdSp);
            no_go(2).x = strfind(html,birdSeen);
            no_go(3).x = strfind(html,noPlayback);
            if ~isempty([no_go.x])
                fprintf('\n\n****no go*****\n\n')
                

% ATTEMPT TO DOWNLOAD FILE
                if ~exist([wgetDir '\download'], 'file')==0, delete('download'), end % if a previous audio file exists, delete it
                system(['wget ' 'https:' i.recordings(nrec).file]); % get audio file located at that URL

                if ~exist([wgetDir '\download'], 'file')==0  % if the audio file was successfully downloaded
                    try 
                        audio=audioread('download');
                        ndwnld = ndwnld + 1;
                    catch
                    end
                    
% RESAMPLE TO TARGET SAMPLING RATE                    
                    i.recordings(nrec).originalFs=str2double( html( ... 
                        strfind(html,fsBefore)+length(fsBefore)  : ...
                        strfind(html,fsAfter)  ) ); 
                    i.recordings(nrec).currentFs=targetFs;
                    if i.recordings(nrec).originalFs ~= targetFs, % if the recording's sampling rate is not the target sample rate
                        audio=resample(audio,targetFs,i.recordings(nrec).originalFs); 
                    end
                    
% SAVE AS .WAV FILE
                    filewav=sprintf('spc%02d_xc%08i_%s.wav', ... % name for the .wav file
                        ...% basicSearchIDs(nbasic), ...
                        i.recordings(nrec).speciesID,...
                        i.recordings(nrec).id, ...
                        strrep(i.recordings(nrec).en,' ','-'));
                    audiowrite(filewav,audio,targetFs) % convert to .wav file
                    system(['move ' filewav ' ' fullfile(dwnldDir,folder,filewav)]); % move to destination folder (for some reason, I can't use wget unless the .exe file in the current directory, so I'd have to put it in each destination folder if I didn't want to change folders)
                    delete('download') % delete file from folder with wget.exe file 

% METADATA - RECORDINGS  
                    i.recordings(nrec).dwnld=1; % 1 indicates the audio was downloaded
                    i.recordings(nrec).sec=length(audio)/i.recordings(nrec).currentFs; % length of the audio file, in seconds
                else disp('error') % the audio file wasn't downloaded because of some error
                end % no error?  
            end % any nogos?
        else disp('extra') % it was because there were already enough files downloaded
        end % <=Ndwnld? 
    end % nrec
    


% DATA METADATA - DOWNLOADED RECORDINGS ONLY
    temp=i.recordings;
    temp([temp.dwnld]==0)=[]; % only save info for recordings that were downloaded
    if nbasic==1, meta.recordings=temp; 
         assignin('base','meta',meta)
    else meta.recordings=[meta.recordings; temp];
    end
% SEARCH METADATA
    meta.searches(nbasic).basic_search = basic_joined;
    meta.searches(nbasic).ID_search = basicSearchIDs(nbasic);
    meta.searches(nbasic).no_downloaded=sum([i.recordings.dwnld]);
    meta.searches(nbasic).total_time_sec=sum([i.recordings.sec]);   
    assignin('base','meta',meta)
    
    
% SPECIES METADATA
    Nspecies = length(listSpecies);
    for nspecies = 1:Nspecies
        i_spec = [i.recordings.spcID] == nspecies;
        meta.species(nspecies).name_species =  listSpecies{nspecies};
        meta.species(nspecies).ID_species = nspecies;
        meta.species(nspecies).no_downloaded = sum([i.recordings(i_spec).dwnld]);
        meta.species(nspecies).total_time_sec = sum([i.recordings(i_spec).sec]);
    end
    
    clear i
    [~,i_sort] = sort([meta.recordings.speciesID]);
    meta.recordings = meta.recordings(i_sort);
    
% SAVE METADATA in download folder
% save after each species is added in case something goes wrong; then
% at least you have the data from the previously-downloaded species
    metaFileName=sprintf('temp_XCaudio_metaData_%s',datestr(now,'yyyy-mm-dd'));
    save(fullfile(dwnldDir,metaFileName),'meta');
end % nbasic
% catch
%     save(sprintf('temp_XCaudio_metaData_ERROR_%s',datestr(now,'yyyy-mm-dd')));
%    
% end % try
end
