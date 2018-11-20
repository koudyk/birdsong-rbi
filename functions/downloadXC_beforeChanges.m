function [meta] = downloadXC(wgetDir,dwnldDir,basic,nums,advanced,...
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

try


if nargin<9 || isempty(start), start = 1; end
if nargin<8 || isempty(targetFs), targetFs=44100; end
if nargin<7 || isempty(nums), nums = 1:length(basic); end
if nargin<6 || isempty(maxQuantity), maxQuantity=Inf; end
%if nargin<6 || isempty(minQuantity), minQuantity=1; end


Nspec=length(basic);
cd(wgetDir)
weboptions('Timeout',60); % (sec) set web timeout to longer time

% strings to search for in the html for the given recording's webpage
noBkgdSp='Background</td><td valign=''top''>none'; % if there are no background species in the recording, this string will be found in the html of the given recording's webpage
fsBefore='<tr><td>Sampling rate</td><td>'; % text before the sampling rate in the html of the given recording's webpage
fsAfter=' (Hz)</td></tr>'; % text after the sampling rate in the html of the given recording's webpage

for nspec=1:Nspec;
    
% MAKE SPECIES FOLDER (i.e., one folder for each cell in 'basic')
    basic_split = strsplit(basic{nspec});
    folder=[sprintf('spc%02d_', nums(nspec)) strjoin(basic_split,'_')];  
    mkdir(dwnldDir, folder)  % folder for audio from given species
    
% GET JSON FOR THE GIVEN SEARCH
    URL_json=['https://www.xeno-canto.org/api/2/recordings?query='... % URL for the json of the list of recordings
        strjoin([basic_split advanced],'%20')];
    i=webread(URL_json);
    
    %%%%%%%%%%%%% make conditional on inclusion of a quality specification in the advanced search terms
    i.recordings(cellfun('isempty',strfind({i.recordings.q},'no score'))==0)=[]; % exclude recordings with no quality rating
    %%%%%%%%%%%%%
    
% (INITIALIZE VARIABLES)
    Nrec=length(i.recordings);
    Ndwnld=min([Nrec maxQuantity]); % set the total number of downloads
    ndwnld=1;
    for nrec=start:Nrec
        fprintf('--------------species %d/%d - recording %d/%d, download %d/%d ------------', ...
            nspec,Nspec,   nrec,Nrec,   ndwnld,Ndwnld)
        i.recordings(nrec).id=str2double(i.recordings(nrec).id); % change id from a string to a number
        i.recordings(nrec).spc=nums(nspec);
        i.recordings(nrec).bkgd=0;
        i.recordings(nrec).dwnld=0;
        
        if ndwnld<=Ndwnld % if it isn't over the desidred number of files
            
% DOWNLOAD HTML OF GIVEN RECORDING'S WEBPAGE            
            html=webread(i.recordings(nrec).url); % download html

% CHECK FOR BACKGROUND SPECIES (on html, not json)
            if ~isempty(strfind(html,noBkgdSp)) % if the line indicating no background species is  found in the html (i.e., if there are NO background species)
                i.recordings(nrec).bkgd=0; % 0 indicates no background species (at least, none indicated)  
            else i.recordings(nrec).bkgd=1; % 1 indicates presence of background species
            end 
            
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
                    filewav=sprintf('spc%02d_xc%08i.wav', nums(nspec), i.recordings(nrec).id ); % name for the .wav file
                    audiowrite(filewav,audio,targetFs) % convert to .wav file
                    system(['move ' filewav ' ' fullfile(dwnldDir,folder,filewav)]); % move to destination folder (for some reason, I can't use wget unless the .exe file in the current directory, so I'd have to put it in each destination folder if I didn't want to change folders)
                    delete('download') % delete file from folder with wget.exe file 

% METADATA - RECORDINGS  
                    i.recordings(nrec).dwnld=1; % 1 indicates the audio was downloaded
                    i.recordings(nrec).sec=length(audio)/i.recordings(nrec).currentFs; % length of the audio file, in seconds
                else disp('error') % the audio file wasn't downloaded because of some error
                end % no error?  
%             else disp('background species'), i.recordings(nrec).bkgd=1; % 1 indicates presence of background species
%             end % no bkgrnd?
        else disp('extra') % it was because there were already enough files downloaded
        end % <=Ndwnld? 
    end % nrec

% DATA METADATA - DOWNLOADED RECORDINGS ONLY
    temp=i.recordings;
    temp([temp.dwnld]==0)=[]; % only save info for recordings that were downloaded
    if nspec==1, meta.recordings=temp; 
        assignin('base','meta',meta)
    else meta.recordings=[meta.recordings; temp];
    end
    
% SPECIES METADATA
    meta.species(nspec).spc_name = folder(7:end);
    meta.species(nspec).spc_num = nums(nspec);
    meta.species(nspec).num_dwnld=sum([i.recordings.dwnld]);
    meta.species(nspec).total_time_sec=sum([i.recordings.sec]);
    
    clear i
    
% SAVE METADATA in download folder
% save after each species is added in case something goes wrong; then
% at least you have the data from the previously-downloaded species
    metaFileName=sprintf('XCaudio_metaData_%s',datestr(now,'yyyy-mm-dd'));
    save(fullfile(dwnldDir,metaFileName),'meta');
end % nspec
catch
    save(sprintf('temp_XCaudio_metaData_%s',datestr(now,'yyyy-mm-dd')));
    
end % try
end


