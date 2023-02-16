% Log what we have here for official Matlab stuff.
ver

% Get home folder on the path.
addpath('/home/matlab');

% Get plexon sdk on the path.
plexonSdkPath = '/home/matlab/Matlab-Offline-Files-SDK';
addpath(genpath(plexonSdkPath));

fprintf('Found Plexon SDK at %s\n', which('mexPlex'));

% Get plx-to-kilosort (from this repo) on the path.
addpath('/home/matlab/plx-to-kilosort');

fprintf('Found plx-to-kilosort at %s\n', which('binFileForPlxFile'));
