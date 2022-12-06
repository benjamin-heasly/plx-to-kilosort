% Convert Plexon spike waveforms to something kilosort can sort.
%
% Inputs:
%
% plxFile -- name of the .plx file to be sorted
% ops -- struct of kilosort config, as from opsForPlxFile()
% chanUnits -- cell array with list of units for each channel:
%            - can be empty, to take all units from all channels
%            - can be cell array of nChans elements, with
%              each element an array of unit indices, for example:
%                chanUnits{1} = 1
%                chanUnits{3} = [1, 10:12]
%              means
%                take unit 1 (unsorted) from channel 1
%                take all units from channel 2 (chanUnits{2} was empty)
%                take units [1, 10, 11, 12] from channel 3
%                take all units from any remaining channels
%              These are all 1-based Matlab indices for units and channels.
%              Entire channels will be skipped, where ops.chanMap.connected
%              is false.
%
% Outputs:
%
% binFile -- path to the converted .bin file with spike data
%
function [binFile, toConvert] = binFileForPlxFile(plxFile, ops, chanUnits)

arguments
    plxFile { mustBeFile }
    ops { mustBeNonempty }
    chanUnits = {};
end

fprintf('Converting Plexon file: %s\n', plxFile);

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

startTime = ops.trange(1);
endTime = ops.trange(end);
if ~isfinite(endTime)
    endTime = header.duration;
end
fprintf('Finding spike timestamps in range %f through %f seconds.\n', startTime, endTime);

binFile = ops.fbinary;
fprintf('Writing to packed binary file: %s\n', binFile);


%% Select channel and unit waveforms segments from the .plx file.
fullread = 1;
[counts.tscounts, ...
    counts.wfcounts, ...
    counts.evcounts, ...
    counts.contcounts] = plx_info(plxFile, fullread);
toConvert = [];
for chanInd = find(ops.chanMap.connected)'
    if numel(chanUnits) < chanInd || isempty(chanUnits{chanInd})
        % Default to all units that have data.
        unitInds = find(counts.wfcounts(:,chanInd));
    else
        % User-specified unit indices.
        unitInds = chanUnits{chanInd};
    end
    for unitInd = unitInds(:)'
        % Locate all the waveform timestamps for this channel-unit pair.
        chanId = chanInd - 1;
        unitId = unitInd - 1;
        [~, ts] = plx_ts(plxFile, chanId, unitId);
        isInRange = ts >= startTime & ts <= endTime;
        fprintf('%d timestamps in range for chan index %d (id %d) unit index %d (id %d)\n', ...
            sum(isInRange), chanInd, chanId, unitInd, unitId);

        timestamps = ts(isInRange);
        thresholdSamples = timestamps * header.frequency;
        firstSamples = thresholdSamples - header.pointsPreThreshold;
        lastSamples = firstSamples + (header.pointsPerWave - 1);

        newToConvert = struct( ...
            'chanId', chanId, ...
            'unitId', unitId, ...
            'timestamp', num2cell(timestamps), ...
            'thresholdSample', num2cell(thresholdSamples), ...
            'firstSample', num2cell(firstSamples), ...
            'lastSample', num2cell(lastSamples));
        toConvert = cat(1, toConvert, newToConvert);
    end
end

[~, order] = sort([toConvert.firstSample]);
toConvert = toConvert(order);


%% Write to the kilosort "fbinary" file.
binFid = fopen(binFile, "w");
if binFid < 0
    error('Could not open file for writing: %s', binFile);
end
closeOnExit = onCleanup(@()fclose(binFid));

% I think:
% - choose an arbitrary in-memory chunk size
% - allocate each chunk array of zeros, int16 [ops.NchanTOT x chunkSize]
% - query toConvert for waveforms that overlap each chunk
% - query overlapping waveforms for subset of data that fits in each chunk
% - fill in the chunk in memory with overlapping waveform subsets
% - write the chunk to the end of the file
% Extra work around chunk edges
% May load each waveform more than once
% But avoids loading everything at once
% And handles when waveforms overlap each other in time, between channels
