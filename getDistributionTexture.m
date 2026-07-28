function tex = getDistributionTexture(window, mode, stdHrzVal, stdVert, ...
    xCenterLeft, xCenterRight, yCenterTri, leftBound, rightBound, newHeight)

persistent texCache

key = sprintf('%s_%.6f_%.6f_%.6f_%.6f', mode, stdHrzVal, stdVert, leftBound, rightBound);

if isempty(texCache)
    texCache = containers.Map('KeyType', 'char', 'ValueType', 'double');
end

if isKey(texCache, key)
    tex = texCache(key);
    return;
end

xRange = round(leftBound):round(rightBound);
yRange = 0:round(newHeight);
[X, Y] = meshgrid(xRange, yRange);

leftDensity = normpdf(X, xCenterLeft, stdHrzVal) .* normpdf(Y, yCenterTri, stdVert);
rightDensity = normpdf(X, xCenterRight, stdHrzVal) .* normpdf(Y, yCenterTri, stdVert);

switch mode
    case 'left'
        density = leftDensity;
    case 'right'
        density = rightDensity;
    case 'both'
        density = leftDensity + rightDensity;
end

density = density - min(density(:));
maxVal = max(density(:));
if maxVal > 0
    density = density / maxVal;
end

img = zeros(size(density, 1), size(density, 2), 3, 'uint8');
img(:,:,2) = uint8(density * 255);        % green increases with density
img(:,:,3) = uint8((1 - density) * 255);  % blue decreases with density

tex = Screen('MakeTexture', window, img);
texCache(key) = tex;

end