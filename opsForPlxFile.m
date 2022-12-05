% Create a kilosort options struct using Plexon header data.
%
% This code is based on some Kilosort code:
%    - Example ops: https://github.com/MouseLand/Kilosort/blob/main/configFiles/StandardConfig_MOVEME.m
%    - Example ops: https://github.com/MouseLand/Kilosort/blob/main/configFiles/configFile384.m
% See https://github.com/MouseLand/Kilosort/tree/main
%
% Inputs:
%
% plxFile -- name of the .plx file to use, default is prompt with dialog
% chanMap -- kilosort channel map struct, as from chanMapForPlxFile()
% existingOps -- struct of existing ops to override what's chosen here
%
% Outputs:
%
% ops -- struct that should work as a kilosort options struct
%
function ops = opsForPlxFile(plxFile, chanMap, existingOps)

arguments
    plxFile = '';
    chanMap = chanMapForPlxFile(plxFile);
    existingOps = struct();
end

%% Start with many defaults from kilosort.

% frequency for high pass filtering (150)
ops.fshigh = 150;

% minimum firing rate on a "good" channel (0 to skip)
ops.minfr_goodchannels = 0.1;

% threshold on projections (like in Kilosort1, can be different for last pass like [10 4])
ops.Th = [10 4];

% how important is the amplitude penalty (like in Kilosort1, 0 means not used, 10 is average, 50 is a lot)
ops.lam = 10;

% splitting a cluster at the end requires at least this much isolation for each sub-cluster (max = 1)
ops.AUCsplit = 0.9;

% minimum spike rate (Hz), if a cluster falls below this for too long it gets removed
ops.minFR = 1/50;

% number of samples to average over (annealed from first to second value)
ops.momentum = [20 400];

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


%% Add what we know from Plexon.
ops.chanMap = chanMap;

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

% Plexon spike waveform sample rate (not the AD "slow" rate).
ops.fs = header.frequency;


%% Add addtional overrides from the caller.
names = fieldnames(existingOps);
for ii = 1:numel(names)
    name = names{ii};
    ops.(name) = existingOps.(name);
end
