% Create a kilosort options struct for sorting Plexon data.
%
% This combines Plexon file data with default kilosort ops taken from the
% kilosort example code.
%
% See for examples:
%  - https://github.com/MouseLand/Kilosort/blob/main/configFiles/StandardConfig_MOVEME.m
%  - https://github.com/MouseLand/Kilosort/blob/main/configFiles/configFile384.m
%
% Inputs:
%
% plxFile -- name of the .plx file to be sorted
% chanMap -- kilosort channel map struct, as from chanMapForPlxFile()
% binFile -- name of the .bin file to sort, as from binFileForPlxFile()
% tempDir -- dir for kilosort to use for working computation (eg fast ssd)
%
% Outputs:
%
% ops -- struct that should work as a kilosort options struct
%
function ops = defaultOpsForPlxFile(plxFile, chanMap, binFile, tempDir)

arguments
    plxFile { mustBeFile }
    chanMap { mustBeNonempty }
    binFile { mustBeNonempty }
    tempDir = fileparts(binFile);
end

%% Start with many defaults from kilosort.
% These are taken from kilosort examples:
%  - https://github.com/MouseLand/Kilosort/blob/main/configFiles/StandardConfig_MOVEME.m
%  - https://github.com/MouseLand/Kilosort/blob/main/configFiles/configFile384.m

% These first 6 seem to be new or updated from Kilosort 2.5 to 3.

% type of data shifting (0 = none, 1 = rigid, 2 = nonrigid)
ops.nblocks = 5;

% spatial scale for datashift kernel
ops.sig = 20;

% splitting a cluster at the end requires at least this much isolation for each sub-cluster (max = 1)
ops.AUCsplit = 0.8;

% frequency for high pass filtering (150)
ops.fshigh = 300;

% how important is the amplitude penalty (like in Kilosort1, 0 means not used, 10 is average, 50 is a lot)
ops.lam = 20;

% threshold on projections (like in Kilosort1, can be different for last pass like [10 4])
ops.Th = [9 9];

% The rest seem to have remained consistent from Kilosort 2.5 to 3.

% minimum spike rate (Hz), if a cluster falls below this for too long it gets removed
ops.minFR = 1/50;

% spatial constant in um for computing residual variance of spike
ops.sigmaMask = 30;

% threshold crossings for pre-clustering (in PCA projection space)
ops.ThPre = 8;

% danger, changing these settings can lead to fatal errors
% options for determining PCs
ops.spkTh = -6;      % spike threshold in standard deviations (-6)
ops.reorder = 1;       % whether to reorder batches for drift correction.
ops.nskip = 25;  % how many batches to skip for determining spike PCs

ops.GPU = 1; % has to be 1, no CPU version yet, sorry
% ops.Nfilt = 1024; % max number of clusters
ops.nfilt_factor = 4; % max number of clusters per good channel (even temporary ones)
ops.ntbuff = 64;    % samples of symmetrical buffer for whitening and spike detection
ops.NT = 64*1024+ ops.ntbuff; % must be multiple of 32 + ntbuff. This is the batch size (try decreasing if out of memory).
ops.whiteningRange = 32; % number of channels to use for whitening each channel
ops.nSkipCov = 25; % compute whitening matrix from every N-th batch
ops.scaleproc = 200;   % int16 scaling of whitened data
ops.nPCs = 3; % how many PCs to project the spikes into
ops.useRAM = 0; % not yet available


%% Add what we know about the chosen .plx file.
ops.fbinary = binFile;
ops.fproc = fullfile(tempDir, 'temp_wh2.dat');

% Chan map could be a struct or the name of a .mat file to load.
ops.chanMap = chanMap;

% Assume binFileForPlxFile() will only write out the "connected" channels.
% Seems obvious here, but in general .bin files can contain extra channels.
ops.NchanTOT = sum(chanMap.connected);

% Assume binFileForPlxFile() will take care of selecting and converting the
% time range of interest, so kilosort should just sort the whole file.
ops.trange = [0, inf];

% Plexon spike waveform sample rate (not the AD "slow" rate).
[header.file, ...
    header.version, ...
    header.frequency, ...
    header.comment, ...
    header.trodalness, ...
    header.pointsPerWave, ...
    header.pointsPreThreshold, ...
    header.spikePeakV, ...
    header.spikeAdBits, ...
    header.slowPeakV, ...
    header.slowAdBits, ...
    header.duration, ...
    header.dateTime] = plx_information(plxFile);
ops.fs = header.frequency;
