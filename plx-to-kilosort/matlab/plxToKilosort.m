% A "main" entrypoint for converting .plx data to kilosort format.
%
% This combines a Plexon raw ".plx" file with several optional arguments,
% and produces several files that can be used with Kilosort:
%   - a raw int16 ".bin" file with neural waveform data
%   - a "chanMap" file that describes the recording probe to Kilosort
%   - an "ops" file that has many parameters expected by Kilosort
%
% Inputs:
%
% plxFile -- name of the .plx file to be sorted
% outDir -- folder to receive output files: bin file, chan map, and ops
%           file (default is same folder as plxFile)
%
% In addition to these positional arguments, several optional name-value
% pairs are allowed.  When provided, these will be passed on to other
% utilites (where they are documented).  These are:
%
% chanX -- see chanMapForPlxFile.m
% chanY -- see chanMapForPlxFile.m
% chanK -- see chanMapForPlxFile.m
% chanIgnore -- see chanMapForPlxFile.m
%
% chanUnits -- see binFileForPlxFile.m
% tRange -- see binFileForPlxFile.m
% mVScale -- see binFileForPlxFile.m
% samplesPerChunk -- see binFileForPlxFile.m
% interpolate -- see binFileForPlxFile.m
%
% ops -- see defaultOpsForPlxFile.m for default Kilosort ops,
%        see loadStruct.m for supported formats of custom ops to pass in
%        here, which will merge with and take precedence over defaults.
%
% Outputs:
%
% chanMapFile -- path to the generated Kilosort chan map file
% binFile -- path to the generated bin data file
% opsFile -- path to the generated Kilosort ops file
function [chanMapMatFile, binFile, opsMatFile] = plxToKilosort(plxFile, outDir, varargin)

arguments
    plxFile { mustBeFile }
    outDir = fileparts(plxFile)
end

arguments (Repeating)
    varargin
end

% There are potentially many options to pass into utilities below.
% Organize them here, making them all named and optional.
parser = inputParser();
parser.CaseSensitive = true;
parser.KeepUnmatched = false;
parser.PartialMatching = false;
parser.StructExpand = true;

% chanMapForPlxFile
parser.addParameter('chanX', []);
parser.addParameter('chanY', []);
parser.addParameter('chanK', []);
parser.addParameter('chanIgnore', []);

% binFileForPlxFile
parser.addParameter('chanUnits', {}, @iscell);
parser.addParameter('tRange', [0, inf], @isnumeric);
parser.addParameter('mVScale', 1000, @isnumeric);
parser.addParameter('samplesPerChunk', 400000, @isnumeric);
parser.addParameter('interpolate', true, @islogical);

% defaultOpsForPlxFile and loadStruct
parser.addParameter('ops', struct());

parser.parse(varargin{:});

start = datetime('now', 'Format', 'uuuuMMdd''T''HHmmss');
fprintf('plxToKilosort Start at: %s\n', char(start));

fprintf('plxToKilosort Converting plx file: %s\n', plxFile);
summarizePlxFile(plxFile, nan);

if ~isfolder(outDir)
    mkdir(outDir);
end


%% chanMapForPlxFile
fprintf('plxToKilosort Generating chan map.\n');
chanMap = chanMapForPlxFile( ...
    plxFile, ...
    parser.Results.chanX, ...
    parser.Results.chanY, ...
    parser.Results.chanK, ...
    parser.Results.chanIgnore);

fprintf('plxToKilosort Generated chan map:\n');
disp(chanMap)

[~, plxBaseName] = fileparts(plxFile);
chanMapMatFile = fullfile(outDir, sprintf('%s-chanMap.mat', plxBaseName));
fprintf('plxToKilosort Writing chan map to %s.\n', chanMapMatFile);
save(chanMapMatFile, 'chanMap');

chanMapJsonFile = fullfile(outDir, sprintf('%s-chanMap.json', plxBaseName));
fprintf('plxToKilosort Writing chan map to %s.\n', chanMapJsonFile);
chanMapJson = jsonencode(chanMap);
writelines(chanMapJson, chanMapJsonFile);


%% binFileForPlxFile
fprintf('plxToKilosort Generating binary file.\n');
[binFile, binTRange] = binFileForPlxFile( ...
    plxFile, ...
    chanMap, ...
    parser.Results.chanUnits, ...
    parser.Results.tRange, ...
    outDir, ...
    parser.Results.mVScale, ...
    parser.Results.samplesPerChunk, ...
    parser.Results.interpolate);

fprintf('plxToKilosort Generated binary file %s.\n', binFile);


%% defaultOpsForPlxFile and loadStruct
fprintf('plxToKilosort Generating default Kilosort ops.\n');
ops = defaultOpsForPlxFile( ...
    plxFile, ...
    chanMap, ...
    binFile, ...
    binTRange);

fprintf('plxToKilosort Merging default ops with any custom ops.\n');
customOps = loadStruct(parser.Results.ops);
customFields = fieldnames(customOps);
for ii = 1:numel(customFields)
    fieldName = customFields{ii};
    ops.(fieldName) = customOps.(fieldName);
end

fprintf('plxToKilosort Here are the final Kilosort ops:\n');
disp(ops)

opsMatFile = fullfile(outDir, sprintf('%s-ops.mat', plxBaseName));
fprintf('plxToKilosort Writing Kilosort ops to %s.\n', opsMatFile);
save(opsMatFile, '-struct', 'ops');

opsJsonFile = fullfile(outDir, sprintf('%s-ops.json', plxBaseName));
fprintf('plxToKilosort Writing Kilosort ops to %s.\n', opsJsonFile);
opsJson = jsonencode(ops);
writelines(opsJson, opsJsonFile);

finish = datetime('now', 'Format', 'uuuuMMdd''T''HHmmss');
duration = finish - start;
fprintf('plxToKilosort Finish at: %s (%s elapsed)\n', char(finish), char(duration));
