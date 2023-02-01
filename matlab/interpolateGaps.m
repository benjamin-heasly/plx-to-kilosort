% Look for gaps in an array and fill them in by interpolating neighbors.
%
% Inputs:
%
% original -- array of samples, possibly containing gaps.
% gapValues -- array of values to treat as gaps in the original, default is
%              [0, nan]
% defaultValue -- value to fill in as default, in case there's a gap at the
%                 beginning or end, or the entire original is one big gap,
%                 default is 0.
%
% Outputs:
%
% interpolated -- a copy of the original where gaps have been filled-in by
%                 interpolating values on either side
%
function interpolated = interpolateGaps(original, gapValues, defaultValue)

arguments
    original { mustBeNumeric }
    gapValues = [0, nan];
    defaultValue = 0;
end

if any(isnan(gapValues))
    isGap = ismember(original, gapValues) | isnan(original);
else
    isGap = ismember(original, gapValues);
end

gapEdges = diff([false; isGap(:); false]);
gapStarts = find(gapEdges == 1);
gapEnds = find(gapEdges == -1) - 1;
interpolated = original;
for gg = 1:numel(gapStarts)
    gapStart = gapStarts(gg);
    gapEnd = gapEnds(gg);
    if gapStart == 1
        leftValue = defaultValue;
    else
        leftValue = original(gapStart-1);
    end

    if gapEnd == numel(original)
        rightValue = defaultValue;
    else
        rightValue = original(gapEnd + 1);
    end

    gapWidth = gapEnd - gapStart + 1;
    gapSamples = linspace(double(leftValue), double(rightValue), gapWidth);
    interpolated(gapStart:gapEnd) = gapSamples;
end
