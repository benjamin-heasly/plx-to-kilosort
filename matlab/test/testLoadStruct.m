% Exercise the loadStruct() code and make correctness assertions.
function testLoadStruct()

% Load this same expected result from various input formats.
expectedStruct = struct( ...
    'zero', 0, ...
    'one', 1, ...
    'pi', 3.14159, ...
    'matrix', [1,2;3,4], ...
    'chars', 'hello', ...
    'struct', struct('a', 1, 'b', 2));

%% Struct as-is.
structAsIs = loadStruct(expectedStruct);
assert(isequal(structAsIs, expectedStruct), 'Should return input struct as-is');


%% Cell array input.
cellInput =  { ...
    'zero', 0, ...
    'one', 1, ...
    'pi', 3.14159, ...
    'matrix', [1,2;3,4], ...
    'chars', 'hello', ...
    'struct', struct('a', 1, 'b', 2)};
structFromCell = loadStruct(cellInput);
assert(isequal(structFromCell, expectedStruct), 'Should convert cell array to struct');


%% JSON file input.
jsonFileInput = fullfile(fileparts(mfilename('fullpath')), 'input.json');
structFromJsonFile = loadStruct(jsonFileInput);
assert(isequal(structFromJsonFile, expectedStruct), 'Should parse JSON file');


%% Mat file input.
matFileInput = fullfile(fileparts(mfilename('fullpath')), 'input.mat');
structFromMatFile = loadStruct(matFileInput);
assert(isequal(structFromMatFile, expectedStruct), 'Should parse Mat file');


%% JSON text input.
jsonTextInput = '{"zero":0,"one":1,"pi":3.14159,"matrix":[[1,2],[3,4]],"chars":"hello","struct":{"a":1,"b":2}}';
structFromJsonText = loadStruct(jsonTextInput);
assert(isequal(structFromJsonText, expectedStruct), 'Should parse JSON text');


%% Other unsupported input.
structFromUnsupportedInput = loadStruct([]);
assert(isequal(structFromUnsupportedInput, struct()), 'Should return empty struct for unsupported input.');
