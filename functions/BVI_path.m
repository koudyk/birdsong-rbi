% 2018.09.22 - set path for the BirdVox-Imitations project

function [dir_data] = BVI_path()
dir_code='C:\Users\User\Documents\MATLAB\Projects\birdsongQBH';
dir_data='F:\0.birdsongQBH\audio\Zenodo-data-release\BirdVox-imitation_mat-audio'; %external harddrive
addpath(genpath(dir_data))
addpath(genpath(dir_code))

end
