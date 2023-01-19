% Log what we have here for official Matlab stuff.
ver

% Get plexon sdk on the path.
plexonSdkPath = '/home/matlab/Matlab-Offline-Files-SDK';
addpath(genpath(plexonSdkPath));

fprintf('Found Plexon SDK at %s\n', which('mexPlex'));

% Get home folder on the path.
addpath('/home/matlab');
