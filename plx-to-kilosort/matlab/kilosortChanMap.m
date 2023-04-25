% Create a kilosort channel map.
%
% This code is based on some Kilosort code:
%    - An example channel map: configFiles/createChannelMapFile.m
%    - How it's actually loaded: Kilosort/preProcess/loadChanMap.m
% See https://github.com/MouseLand/Kilosort/tree/main
%
% Inputs:
%
% nChans -- overall number of channels on a probe (whether connected or not)
% chanX -- probe x-location of each channel, defaults to all ones
% chanY -- probe y-location of each channel, defaults to 1:Nchannels
% chanK -- cluster that each channel belongs to, defaults to all ones
% connected -- selector for which probe channels are connected
% squeezeConnected -- Whether to omit non-connected channels from the
%                     returned chanMap.  Default is false -- include
%                     channels as given.
%
% Outputs:
%
% chanMap -- struct that should work as a kilosort channel map
%
function chanMap = kilosortChanMap(nChans, chanX, chanY, chanK, connected, squeezeConnected)

arguments
    nChans {mustBeNonNan}
    chanX = [];
    chanY = [];
    chanK = [];
    connected = [];
    squeezeConnected = false;
end

chanMap.Nchannels = nChans;
chanMap.chanMap = (1:nChans)';

if isempty(connected)
    chanMap.connected = true(nChans, 1);
else
    chanMap.connected = connected;
end

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

if squeezeConnected
    fprintf('kilosortChanMap squeezeConnected is true: omitting non-connected channels.\n');

    chanMap.xcoords = chanMap.xcoords(connected);
    chanMap.ycoords = chanMap.ycoords(connected);
    chanMap.kcoords = chanMap.kcoords(connected);

    nConnected = numel(chanMap.xcoords);
    chanMap.chanMap = (1:nConnected)';
    chanMap.Nchannels = nConnected;
    chanMap.connected = true(nConnected, 1);
end
