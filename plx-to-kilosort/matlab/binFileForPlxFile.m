% Convert Plexon spike waveforms to something kilosort can sort.
%
% This writes a new .bin file of packed 16-bit samples, containing Plexon
% triggered waveform segments from the given .plx file.  In between the
% waveform segments will contain zero-valued samples that fill out the
% time.
%
% This conversion is slightly awkward because of data ordering.
%
% The Plexon SDK presents waveforms per channel and unit, and the returns
% data spanning the entire file timeline.  Presumably this is the access
% pattern Plexon is trying to optimize with .plx files (?).  On the other
% hand, for kilosort we want to present data sequentially in time, with all
% channels represented at each time point.
%
% So we have to "rotate" the data.  Since the files can be large, we want
% to avoid reading the entire .plx file into memory.  It also turns out we
% need to minimize calls to the Plexon SDK, because this turns out to be
% the slow step in conversion.
%
% It's slow, despite .plx files being designed for some kind of data access
% pattern -- right?  Maybe the optimized access pattern is different from
% what the SDK implements, for some reason.
%
% To minimize SDK calls, we extract each channel of data from the .plx file
% once, and write it out to a temp file of packed, sequential 16-bit
% samples.  Once we have the temp file for each channel, we're done with
% the SDK.  We made as few calls as possible to get the data, and we only
% loaded a channel at a time instead of the entire file.
%
% Note that each channel's temp file contains data from all units on the
% same channel.  This is based on the assumption that units in the same
% channel will never clobber each other -- either the units are disjoint
% subsets of the channel data, or they are exactly redundant.  Either way,
% units should not contain arbitrary, independent waveforms that would
% interfere with each other.
%
% Finally, we read the channel temp files in chunks and zip
% them together into one big bin file.  This is pretty quick because we can
% fseek through the packed samples to locate each chunk.  Working in chunks
% of fixed size avoids reading the entire data set back into memory.  The
% resulting output file has packed 16-bit samples arranged sequentially in
% time, with each channel represented at each time point, as kilosort
% expects.
%
% Inputs:
%
% plxFile -- name of the .plx file to be sorted
% connected -- logical array indicating which channels to extract and
%              convert.
% chanUnits -- cell array with list of units for each channel:
%            - can be empty, to take all units from all channels
%            - can be cell array of nChans elements, with
%              each element an array of unit indices, for example:
%                chanUnits{1} = 1
%                chanUnits{3} = [1, 10:12]
%              This example means:
%                take unit 1 (unsorted) from channel 1
%                take all units from channel 2 (chanUnits{2} empty by default)
%                take units [1, 10, 11, 12] from channel 3
%                take all units from any remaining channels (empty by default)
%              These are all 1-based Matlab indices for units and channels,
%              not 0-based Plexon ids for units and channels.
% tRange -- time range [startTime, endTime] to extract from plxFile and
%           convert to .bin, default is the entire .plx timeline [0 inf]
% binDir -- directory where the new .bin file should be written, default is
%           pwd().
% mVScale -- Scale factor for representing Plexon millivolt samples as
%            int16 samples in the binFile, default is 1000 which makes the
%            int16 values into microvolts and should preserve waveform
%            shapes.
% samplesPerChunk -- number of samples (across all channels) to zip up and
%                    write out at a time.  Default is 400000, and the exact
%                    value should not matter much.
% interpolate -- whether to fill in interpolated values between recorded
%                waveforms.  If false, leaves gaps of zeros between
%                waveforms.  Default is true -- do the interpolation.
% endPadding -- seconds of padding to add at the end of the binary file --
%               default is 1 second.
%
% Outputs:
%
% binFile -- path to the converted .bin file with range of .plx spike data
% tRange -- time range in seconds that covers the entire converted
%           timeline, ignoring endPadding.  Similar to given tRange
%           argument, but always starts and 0 and ends at a finite end
%           time, [0 endTime]
function [binFile, binTRange] = binFileForPlxFile(plxFile, connected, chanUnits, tRange, binDir, mVScale, samplesPerChunk, interpolate, endPadding)

arguments
    plxFile { mustBeFile }
    connected { mustBeNonempty }
    chanUnits = {};
    tRange = [0 inf];
    binDir = pwd();
    mVScale = 1000;
    samplesPerChunk = 400000;
    interpolate = true;
    endPadding = 1;
end

% Regarding mVScale: Here's an "official" example from Jennifer Colonnel
% where they also write out int16 samples as microvolts:
% https://github.com/MouseLand/Kilosort/blob/main/eMouse_drift/make_eMouseData_drift.m#L612

start = datetime('now', 'Format', 'uuuuMMdd''T''HHmmss');
fprintf('binFileForPlxFile Start at %s\n', char(start));

fprintf('binFileForPlxFile Converting .plx file: %s\n', plxFile);

if ~isfolder(binDir)
    mkdir(binDir);
end

[~, plxName, plxExt] = fileparts(plxFile);
binFile = fullfile(binDir, [plxName plxExt '.bin']);
fprintf('binFileForPlxFile Destination .bin file: %s\n', binFile);

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

startTime = tRange(1);
if isfinite(tRange(end))
    endTime = tRange(end);
    endTimeComment = 'the given end time';
else
    endTime = header.duration;
    endTimeComment = 'to end of file';
end
fprintf('binFileForPlxFile Selecting waveforms in range %f - %f seconds (%s).\n', ...
    startTime, endTime, endTimeComment);
binTRange = [0, endTime - startTime];

paddingSamples = ceil(header.frequency * endPadding);
fprintf('binFileForPlxFile Adding %f seconds (%d samples) to the end of the output binary.\n', ...
    endPadding, paddingSamples);

% Compute global sample numbers to represent in the new binary file.
% These are ficticious sample numbers, as if Plexon had sampled the entire
% spike waveform continuously at the high spike channel framerate.
% We might take them all, or a subrange determined by tRange.
binFirstSample = uint64(startTime * header.frequency) + 1;
binLastSample = uint64(endTime * header.frequency);
binSampleCount = binLastSample - binFirstSample + 1 + paddingSamples;
connectedChanInds = find(connected);
connectedChanCount = numel(connectedChanInds);
fprintf('binFileForPlxFile Expecting %u samples across %u connected channels.\n', ...
    binSampleCount, connectedChanCount);

bytesPerSample = 2;
binByteCount = binSampleCount * connectedChanCount * bytesPerSample;
fprintf('binFileForPlxFile Expecting %u bytes total (%u samples * %u channels * %u bytes per sample).\n', ...
    binByteCount, binSampleCount, connectedChanCount, bytesPerSample);


%% Write each .plx channel to its own temp .bin file.
% This is because we want to avoid reading the while .plx file into memory.
% We would prefer to read all .plx file channels, in chunks of time.
% But the Plexon SDK doesn't expose this operation!
% Instead, the best we can do is load one whole channel at a time.
% Later, we'll zip the channel files together, in chunks of time.

fullread = 1;
[counts.tscounts, ...
    counts.wfcounts, ...
    counts.evcounts, ...
    counts.contcounts] = plx_info(plxFile, fullread);

chanBinFiles = cell(connectedChanCount, 1);
for cci = 1:connectedChanCount
    chanInd = connectedChanInds(cci);

    chanBinName = sprintf('%s%s.chan%u.bin', plxName, plxExt, chanInd);
    chanBinFile = fullfile(binDir, chanBinName);
    chanBinFiles{cci} = chanBinFile;
    fprintf('binFileForPlxFile Create temp .bin file for chanInd %u: %s\n', chanInd, chanBinFile);

    % Pick which units to convert for this channel
    if numel(chanUnits) < chanInd || isempty(chanUnits{chanInd})
        % Default to all units that have data.
        % silly off by one error in plexon sdk returned counts.
        unitInds = find(counts.wfcounts(:, chanInd + 1));
    else
        % User-specified unit indices.
        unitInds = chanUnits{chanInd};
    end

    % Load each unit into memory and select its waveforms in tRange.
    % This stores up to the whole channel in memory, depending on tRange.
    % This read seems to be the slowest part of the conversion.
    chanData = zeros([binSampleCount, 1], 'int16');
    for unitInd = unitInds(:)'
        unitId = unitInd - 1;

        fprintf('binFileForPlxFile Extracting waveforms for chanInd %u, unitId %u\n', chanInd, unitId);

        [~, waveSampleCount, waveTimes, waveData] = plx_waves_v(plxFile, chanInd, unitId);
        waveThreshSamples = uint64(waveTimes * header.frequency);
        waveFirstSamples = uint64(waveThreshSamples - header.pointsPreThreshold);
        waveLastSamples = waveFirstSamples + uint64(waveSampleCount - 1);
        waveInRange = waveFirstSamples >= binFirstSample & waveLastSamples <= binLastSample;
        for ww = find(waveInRange)'
            chanStart = waveFirstSamples(ww) - binFirstSample + 1;
            chanEnd = waveLastSamples(ww) - binFirstSample + 1;
            chanData(chanStart:chanEnd) = int16(mVScale * waveData(ww, :));
        end
    end

    if interpolate
        fprintf('binFileForPlxFile interpolating gaps between waveforms for chanInd %u.\n', chanInd);
        gapValue = int16(0);
        defaultValue = int16(0);
        chanData = interpolateGaps(chanData, gapValue, defaultValue);
    end

    fprintf('binFileForPlxFile Data range for chanInd %d: min %f max %f\n', chanInd, min(chanData), max(chanData));

    % onCleanup handler fires after completion or error -- either way.
    chanFid = fopen(chanBinFile, 'w');
    chanFidCleanup = onCleanup(@()fclose(chanFid));
    fwrite(chanFid, chanData, 'int16');

    % Prompt file to close each iteration instead of later at file exit.
    chanFidCleanup = [];
end


%% Zip together the channel .bin files above into one big .bin file.
% Again, we don't want to read these entirely into memory.
% So we read and write in chunks of fized size.
% We can to this in chunks now, because the chan .bin files are fseek-able.

% onCleanup handler fires after completion or error -- either way.
binFid = fopen(binFile, "w");
binFidCleanup = onCleanup(@()fclose(binFid));

binChunkCount = ceil(double(binSampleCount) / samplesPerChunk);
for bci = 1:binChunkCount
    chunkFirstSample = (bci - 1) * samplesPerChunk + 1;
    chunkLastSample = min(chunkFirstSample + samplesPerChunk - 1, binSampleCount);
    chunkSampleCount = chunkLastSample - chunkFirstSample + 1;
    fprintf('binFileForPlxFile Merging temporary .bin files, chunk %u / %u, samples %u:%u (%u total).\n', ...
        bci, binChunkCount, chunkFirstSample, chunkLastSample, chunkSampleCount);

    chunkSize = [connectedChanCount, chunkSampleCount];
    chunkData = zeros(chunkSize, 'int16');

    chunkByteOffset = (chunkFirstSample -1) * 2;
    for cci = 1:connectedChanCount
        chanBinFile = chanBinFiles{cci};

        % onCleanup handler fires after completion or error -- either way.
        chanFid = fopen(chanBinFile, 'r');
        chanFidCleanup = onCleanup(@()fclose(chanFid));

        % Extract the current chunk for this channel.
        fseek(chanFid, chunkByteOffset, 'bof');
        chunkData(cci, :) = fread(chanFid, chunkSampleCount, 'int16');

        % Prompt file to close each iteration instead of later at file exit.
        chanFidCleanup = [];
    end

    fwrite(binFid, chunkData, 'int16');
end

fprintf('binFileForPlxFile Deleting temporary .bin files.\n');
cellfun(@(chanBinFile) delete(chanBinFile), chanBinFiles);

finish = datetime('now', 'Format', 'uuuuMMdd''T''HHmmss');
duration = finish - start;
fprintf('binFileForPlxFile Finish at: %s (%s elapsed)\n', char(finish), char(duration));
