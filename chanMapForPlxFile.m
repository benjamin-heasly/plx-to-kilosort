% Create a kilosort channel map for sorting Plexon data.
%
% This code is based on some Kilosort code:
%    - An example channel map: configFiles/createChannelMapFile.m
%    - How it's actually loaded: Kilosort/preProcess/loadChanMap.m
% See https://github.com/MouseLand/Kilosort/tree/main
%
% Inputs:
%
% plxFile -- name of the .plx file to be sorted
% chanX -- probe x-location of each channel, defaults to all ones
% chanY -- probe y-location of each channel, defaults to 1:Nchannels
% chanK -- cluster that each channel belongs to, defaults to all ones
% chanIgnore -- channel indexes (1-based) to treat as disconnected
%
% Outputs:
%
% chanMap -- struct that should work as a kilosort channel map
% plxFile -- .plx file that was used (passed in or chosen from dialog)
%
function [chanMap, plxFile] = chanMapForPlxFile(plxFile, chanX, chanY, chanK, chanIgnore)

arguments
    plxFile { mustBeFile }
    chanX = [];
    chanY = [];
    chanK = [];
    chanIgnore = [];
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

% Create the chanMap struct using fieldnames expected by kilosort.
chanMap.Nchannels = nChans;
chanMap.chanMap = 1:nChans;

chanMap.connected = false(nChans, 1);
chanMap.connected(connectedChanInds) = true;
chanMap.connected(chanIgnore) = false;

if isempty(chanX)
    chanMap.xcoords = ones(nChans, 1);
else
    chanMap.xcoords = chanX;
end

if isempty(chanY)
    chanMap.ycoords = (1:nChans)';
else
    chanMap.ycoords = chanY;
end

if isempty(chanK)
    chanMap.kcoords = ones(nChans, 1);
else
    chanMap.kcoords = chanK;
end
