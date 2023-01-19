% Create a phy/spyking-circus .prb file for sorting Plexon data.
%
% .prb is a Python script that has definitions like this:
%
% total_nb_channels = 4
% radius = 100
% channel_groups = {
%     0: {
%         "channels": [0, 1, 2, 3],
%         "geometry": {0: [16.0, 0.0], 1: [48.0, 0.0], 2: [0.0, 20.0], 3: [32.0, 20.0]},
%     },
% }
%
% Inputs:
%
% plxFile -- name of the .plx file to be sorted
% chanX -- probe x-location of each channel, defaults to all ones
% chanY -- probe y-location of each channel, defaults to 1:Nchannels
% chanIgnore -- channel indexes (1-based) to treat as disconnected
% radius -- spatial width (um) of the templates
% prbFile -- name of the .prb file to be written, defaults to [plxFile].prb
%
% Outputs:
%
% prbFile -- .prb file that was written
%
function prbFile = prbForPlxFile(plxFile, chanX, chanY, chanIgnore, radius, prbFile)

arguments
    plxFile { mustBeFile }
    chanX = [];
    chanY = [];
    chanIgnore = [];
    radius = 100;
    prbFile = [plxFile '.prb']
end

% Plexon data counts (from block headers, I think).
fullread = 1;
[counts.tscounts, ...
    counts.wfcounts, ...
    counts.evcounts, ...
    counts.contcounts] = plx_info(plxFile, fullread);

% From plx_info.m:
%   Note that for tscounts, wfcounts, the unit,channel indices i,j are off by one.
%   That is, for channels, the count for channel n is at index n+1, and for units,
%    index 1 is unsorted, 2 = unit a, 3 = unit b, etc
%   The dimensions of the tscounts and wfcounts arrays are
%     (NChan+1) x (MaxUnits+1)
%   where NChan is the number of spike channel headers in the plx file
% However, it appears they wrote the size backwards, it seems to be:
%   (MaxUnits+1) x (NChan+1)
nChans = size(counts.wfcounts, 2) - 1;
[~, connectedChanInds] = find(counts.wfcounts);

connected = false(nChans, 1);
connected(connectedChanInds - 1) = true;
connected(chanIgnore) = false;

% Total count of channels in the data file.
% This expects binFileForPlxFile to only write out the connected channels.
totalNbChannels = sum(connected);
channels = find(connected);

% Describe geometry for all channels, whether connected or not.
if isempty(chanX)
    x = ones(nChans, 1);
else
    x = chanX;
end

if isempty(chanY)
    y = (1:nChans)';
else
    y = chanY;
end

geometry = cell([nChans, 1]);
for ii = 1:nChans
    % spyking circus (and others?) require 0-based channel indices
    chan = ii - 1;
    geometry{ii} = sprintf('%d: [%f, %f]', chan, x(ii), y(ii));
end

% Splat out some Python code.
% It would be better to do this in Python with probeinterface.
% https://github.com/SpikeInterface/probeinterface

% total_nb_channels = 4
totalChanPy = sprintf('total_nb_channels = %d\n', totalNbChannels);

% radius = 100
radiusPy = sprintf('radius = %f\n', radius);

% channel_groups = {
%     0: {
%         "channels": [0, 1, 2, 3],
%         "geometry": {0: [16.0, 0.0], 1: [48.0, 0.0], 2: [0.0, 20.0], 3: [32.0, 20.0]},
%     }
% }
% spyking circus (and others?) require 0-based channel indices
chanListPy = [sprintf('%d', channels(1) - 1), sprintf(', %d', channels(2:end) - 1)];
geometryListPy = [geometry{1}, sprintf(', %s', geometry{2:end})];
chanGroupsPy = [ ...
    ['channel_groups = {', newline], ...
    ['    0: {', newline], ...
    ['        "channels": [', chanListPy, '],', newline], ...
    ['        "geometry": {', geometryListPy, '},', newline], ...
    ['    }', newline], ...
    ['}', newline], ...
    ];

% Write it out as a .prb file.
prbPy = [totalChanPy, radiusPy, chanGroupsPy];
fid = fopen(prbFile, 'w');
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, prbPy);
