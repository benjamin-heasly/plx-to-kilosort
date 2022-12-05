% Summarize a Plexon .plx file with general config info plots of data.
%
% Inputs:
%
% fileName -- name of the .plx file to load, default is prompt with dialog
% startTime -- starting location of data to plot, default is 0 seconds,
%              use nan to skip plotting
% duration -- how much data to plot aftart startTime, default is 30
%             seconds, use inf for the whole file
%
% Outputs:
%
% header -- struct with header info from the chosen .plx file
% counts -- struct with data counts from the .plx file
%
function [header, counts] = summarizePlxFile(fileName, startTime, duration, firstFig)

arguments
    fileName = '';
    startTime = 0;
    duration = 30;
    firstFig = 1;
end

%% Header info.
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
    header.dateTime] = plx_information(fileName);

if ~isfinite(duration)
    duration = header.duration;
end


%% Data counts.
fullread = 1;
[counts.tscounts, ...
    counts.wfcounts, ...
    counts.evcounts, ...
    counts.contcounts] = plx_info(header.file, fullread);

disp('Timestamps and waveforms:')

% Timestamps.
% tscounts(i, j) is the number of timestamps for channel j-1, unit i
[tsi, tsj] = find(counts.tscounts);
spikesCount = numel(tsi);
for ii = 1:spikesCount
    channelId = tsj(ii) - 1;
    unitId = tsi(ii) - 1;
    fprintf('  %d timestamps for spike channel %d, unit %d\n', ...
        counts.tscounts(tsi(ii), tsj(ii)), channelId, unitId);
end

% Waveforms.
% wfcounts(i, j) is the number of waveforms for channel j-1, unit i
[wfi, wfj] = find(counts.wfcounts);
for ii = 1:numel(wfi)
    channelId = tsj(ii) - 1;
    unitId = tsi(ii) - 1;
    fprintf('  %d waveforms for spike channel %d, unit %d\n', ...
        counts.wfcounts(wfi(ii), wfj(ii)), channelId, unitId);
end

disp('Digital events:')

% Events.
% evcounts(i) is the number of events for event channel i
[~, eventChannels] = plx_event_chanmap(header.file);
[~, eventNames] = plx_event_names(header.file);
evi = find(counts.evcounts);
eventsCount = numel(evi);
for ii = 1:eventsCount
    eventId = eventChannels(evi(ii));
    fprintf('  %d events for event channel %d -- %s\n', ...
        counts.evcounts(evi(ii)), eventId, strip(eventNames(evi(ii), :)));
end

disp('AD channels:')

% Continuous AKA slow sample counts.
% contcounts(i) is the number of continuous for slow channel i-1
[~, adNames] = plx_adchan_names(header.file);
adi = find(counts.contcounts);
adCount = numel(adi);
for ii = 1:adCount
    channelId = adi(ii) - 1;
    fprintf('  %d samples for continuous / slow channel %d -- %s\n', ...
        counts.contcounts(adi(ii)), channelId, strip(adNames(adi(ii), :)));
end

if isnan(startTime)
    return
end

%% Plot continuous data from ad channels.
figure(firstFig);
clf();

xRange = [startTime, min(startTime + duration, header.duration)];

for ii = 1:adCount
    channelId = adi(ii) - 1;

    %   adfreq - digitization frequency for this channel
    %   n - total number of data points 
    %   ts - array of fragment timestamps (one timestamp per fragment, in seconds)
    %   fn - number of data points in each fragment
    %   adv - array of a/d values converted to millivolts
    [adfreq, ~, ts, fn, adv] = plx_ad_v(header.file, channelId);

    fragmentTimes = (0:(fn-1)) / adfreq;
    adTimes = repmat(fragmentTimes', 1, numel(ts));
    fragmentOffsets = repmat(ts, fn, 1);
    sampleTimes = adTimes + fragmentOffsets;
    waveSelector = find(sampleTimes >= xRange(1) & sampleTimes <= xRange(2));

    subplot(adCount, 1, ii);
    plot(sampleTimes(waveSelector), adv(waveSelector), 'g.');
    adLabel = sprintf('%d: %s', channelId, strip(adNames(adi(ii), :)));
    title(adLabel);
    ylabel('mV');
    xlim(xRange);
end

subplot(adCount, 1, adCount);
xlabel('sample time (s)');


%% Plot timestamped waveform segments from spike channels.
% Timestamps tell us when a threshold was crossed.
% Waveforms around each timestamp tell us the neural signal in a window.
% The rest of the neural signal was not persisted!
figure(firstFig + 1);
clf();
figure(firstFig + 2);
clf();

% Each waveform segment occupies a window around the threshold crossing.
% We get some number of samples before and after the crossing.
windowSamples = (1:header.pointsPerWave) - header.pointsPreThreshold - 1;
windowTimes = windowSamples / header.frequency;

spikesCount = numel(tsi);
for ii = 1:spikesCount
    channelId = tsj(ii) - 1;
    unitId = tsi(ii) - 1;

    %   n - number of waveforms
    %   npw - number of points in each waveform
    %   ts - array of timestamps (in seconds) 
    %   wave - array of waveforms [npw, n] converted to mV
    [n, npw, ts, wavev] = plx_waves_v(header.file, channelId, unitId);
    waveTimes = repmat(windowTimes, n, 1);
    windowOffsets = repmat(ts, 1, npw);
    sampleTimes = waveTimes + windowOffsets;
    waveSelector = find(sampleTimes >= xRange(1) & sampleTimes <= xRange(2));
    tsSelector = find(ts >= xRange(1) & ts <= xRange(2));

    % Waveforms over time.
    figure(firstFig + 1);
    subplot(spikesCount, 1, ii);
    thresholdValues = wavev(tsSelector, header.pointsPreThreshold + 1);
    plot(sampleTimes(waveSelector), wavev(waveSelector), '.b', ...
        ts(tsSelector), thresholdValues, 'y*');
    spikesLabel = sprintf('Channel %d unit %d waveforms', channelId, unitId);
    title(spikesLabel);
    ylabel('mV');
    xlim(xRange);

    % Waveforms aligned on threshold trigger.
    figure(firstFig + 2);
    subplot(spikesCount, 1, ii);
    plot(waveTimes(waveSelector), wavev(waveSelector), '.b', ...
        zeros(size(thresholdValues)), thresholdValues, 'y*');
    triggerLabel = sprintf('Channel %d unit %d windows', channelId, unitId);
    title(triggerLabel);
    ylabel('mV');
    xlim(windowTimes([1,end]));
end

figure(firstFig + 1);
subplot(spikesCount, 1, spikesCount);
xlabel('sample time (s)');

figure(firstFig + 2);
subplot(spikesCount, 1, spikesCount);
xlabel('window time (s)');


%% Plot times and strobe values from event channels.
figure(firstFig + 3);
clf();

for ii = 1:eventsCount
    %   n - number of timestamps
    %   ts - array of timestamps (in seconds)
    %   sv - array of strobed event values (filled only if channel is 257)
    eventId = eventChannels(evi(ii));
    [~, ts, sv] = plx_event_ts(header.file, eventId);
    eventSelector = find(ts >= xRange(1) & ts <= xRange(2));

    subplot(eventsCount, 1, ii);
    plot(ts(eventSelector), sv(eventSelector), 'ro');
    eventLabel = sprintf('%d: %s', eventId, strip(eventNames(evi(ii), :)));
    title(eventLabel)
    ylabel('word')
    xlim(xRange)
end

subplot(eventsCount, 1, eventsCount);
xlabel('event time (s)');

