% Load data from a few formats into a Matlab struct.
%
% This util is intended as a convenience for getting data into a Matlab
% struct.  It accepts the following input types:
%  - struct -- returns it as-is
%  - cell array -- converts to struct with struct(input{:})
%  - string name of .json file -- loads struct with fileread() and jsondecode()
%  - string name of other file -- loads struct = load(input)
%  - other string -- parses JSON text with jsondecode()
%  - otherwise -- returns an empty struct by default
%
% Inputs:
%
% input -- a struct, cell array, or string file name
%
% Outputs:
%
% s -- a struct parsed from the the input, or empty struct if the input
%      could not be parsed.
function s = loadStruct(input)

if isstruct(input)
    fprintf('loadStruct Returning input struct as-is.\n');
    s = input;
elseif iscell(input)
    fprintf('loadStruct Converting input cell array to struct.\n');
    s = struct(input{:});
elseif ischar(input) && isfile(input) && (endsWith(input, '.json'))
    fprintf('loadStruct Parsing input as a JSON file: %s.\n', input);
    text = fileread(input, 'Encoding', 'UTF-8');
    s = jsondecode(text);
elseif ischar(input) && isfile(input)
    fprintf('loadStruct Loading input as a Matlab data file: %s.\n', input);
    s = load(input);
elseif ischar(input)
    fprintf('loadStruct Parsing input as JSON text.\n');
    s = jsondecode(input);
else
    fprintf('loadStruct Returning empty struct for unrecognizezd input: %s.\n', mat2str(input));
    s = struct();
end
