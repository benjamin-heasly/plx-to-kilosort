% Sanity check for mexPlex installation adapted from Plexon's build_and_verify_mexPlex.m.
%
% If the mexPlex installation is good this function will:
%   - return logical true
%   - print the message: "VERIFICATION TESTS PASSED"
%
% The plexonSdkDir argument should be the location of the Plexon "Matlab Offline Files SDK."
% This is the dir that contains a "mexPlex" subdir and compiled mex executables,
% Not the "mexPlex" subdir itself.
%
function success = testMexPlex(plexonSdkDir)

arguments
    plexonSdkDir = fullfile('/', 'home', 'matlab', 'Matlab-Offline-Files-SDK')
end

plexonTestDir = fullfile(plexonSdkDir, 'mexPlex', 'tests');
cd(plexonTestDir);

disp('testMexPlex starting test.');

% Load some test fixture data.
load('mexPlexData1.dat', '-mat');

% Verify that mexPlex generates the same data
t=evalc('res = verify_mexplex(data, pwd);');

if res == 0
    success = false;
    disp('VERIFICATION FAILED');
    t
else
    success = true;
    disp('VERIFICATION TESTS PASSED');
end

disp('testMexPlex test complete.');
