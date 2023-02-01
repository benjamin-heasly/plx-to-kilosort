% Exercise the interpolateGaps() code and make correctness assertions.
function testInterpolateGaps()

%% No gaps Row.
original = 1:20;
interpolated = interpolateGaps(original);
assert(isequal(interpolated, original), 'Should return input as-is when it has no gaps.')


%% No gaps Column.
original = (1:20)';
interpolated = interpolateGaps(original);
assert(isequal(interpolated, original), 'Should return input as-is when it has no gaps.')


%% Empty.
original = [];
interpolated = interpolateGaps(original);
assert(isequal(interpolated, original), 'Should return input as-is when it is empty.')


%% Scalar Gap.
original = 0;
default = 42;
interpolated = interpolateGaps(original, 0, default);
assert(isequal(interpolated, default), 'Should return scalar default when original is a scalar gap.')


%% Scalar Not a Gap.
original = 1;
default = 42;
interpolated = interpolateGaps(original, 0, default);
assert(isequal(interpolated, original), 'Should return input as-is when it is a scalar and not a gap.')


%% Leading Gap.
original = [0 0 0 0 0 0 10 10 10 10 10];
interpolated = interpolateGaps(original, 0, 5);
expected = [5 6 7 8 9 10 10 10 10 10 10];
assert(isequal(interpolated, expected), 'Should replace leading gap with interpolation from default value.')


%% Trailing Gap.
original = [10 10 10 10 10 0 0 0 0 0 0];
interpolated = interpolateGaps(original, 0, 5);
expected = [10 10 10 10 10 10 9 8 7 6 5];
assert(isequal(interpolated, expected), 'Should replace trailing gap with interpolation to default value.')


%% Central Gap.
original = [1 2 3 4 5 0 0 0 0 0 5 4 3 2 1];
interpolated = interpolateGaps(original, 0);
expected = [1 2 3 4 5 5 5 5 5 5 5 4 3 2 1];
assert(isequal(interpolated, expected), 'Should replace central gap with interpolation between neighbors.')


%% Several Gaps.
original = [0 2 3 4 5 6 nan nan 9 10 11 12 0 nan 0 15 16 17 18 0 0];
default = 42;
interpolated = interpolateGaps(original, [0, nan], default);
expected = [2 2 3 4 5 6 6 9 9 10 11 12 12 13.5 15 15 16 17 18 18 default];
assert(isequal(interpolated, expected), 'Should replace gaps with various locations and gap values.')


%% One giant gap.
original = zeros(20, 1);
default = 42;
interpolated = interpolateGaps(original, 0, default);
expected = default * ones(size(original));
assert(isequal(interpolated, expected), 'Should return all defaults when original is all gaps.')


%% Int values
original = int16([0 0 0 0 0 10 10 10 10 10]);
interpolated = interpolateGaps(original, 0, 5);
expected = int16([5 6 8 9 10 10 10 10 10 10]);
assert(isequal(interpolated, expected), 'Should interpolate ints by rounding.')
