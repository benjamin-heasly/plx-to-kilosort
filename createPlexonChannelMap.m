% Create a kilosort channel map using on Plexon header data.
%
% This code is based on some Kilosort code:
%    - An example channel map: configFiles/createChannelMapFile.m
%    - How it's actually loaded: Kilosort/preProcess/loadChanMap.m
% See https://github.com/MouseLand/Kilosort/tree/main
%
% Inputs:
%
% plxFile -- name of the .plx file to use, default is prompt with dialog
% x -- probe x-location of each channel, defaults to all ones
% y -- probe y-location of each channel, defaults to 1:Nchannels
% k -- cluster that each channel belongs to, defaults to all ones
%
% Outputs:
%
% chanMap -- struct that should work as a kilosort channel map
%
function chanMap = createPlexonChannelMap(plxFile, x, y, k)

arguments
    plxFile = '';
    x = [];
    y = [];
    k = [];
end

% Plexon file header.
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

% Plexon data counts (from block headers, I think).
fullread = 1;
[counts.tscounts, ...
    counts.wfcounts, ...
    counts.evcounts, ...
    counts.contcounts] = plx_info(header.file, fullread);


% From plx_info.m:
%
% Note that for tscounts, wfcounts, the unit,channel indices i,j are off by one. 
% That is, for channels, the count for channel n is at index n+1, and for units,
%  index 1 is unsorted, 2 = unit a, 3 = unit b, etc
% The dimensions of the tscounts and wfcounts arrays are
%   (NChan+1) x (MaxUnits+1)
% where NChan is the number of spike channel headers in the plx file
%
% However, it appears they wrote the size backwards, it seems to be: 
%   (MaxUnits+1) x (NChan+1)
maxChannels = size(counts.wfcounts, 2) - 1;
[~, channelIndices] = find(counts.wfcounts);

% Format for kilosort.
chanMap.Nchannels = maxChannels;
chanMap.chanMap = 1:maxChannels;

chanMap.connected = false(maxChannels, 1);
chanMap.connected(channelIndices) = true;

if isempty(x)
    chanMap.xcoords = ones(maxChannels, 1);
else
    chanMap.xcoords = x;
end

if isempty(y)
    chanMap.ycoords = (1:maxChannels)';
else
    chanMap.ycoords = y;
end

if isempty(k)
    chanMap.kcoords = ones(maxChannels, 1);
else
    chanMap.kcoords = k;
end
