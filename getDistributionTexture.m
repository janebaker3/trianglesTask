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

lightGreen = [0, 255, 0];
blue = [0, 0, 255];
yellow = [0, 255, 0];

leftNorm = leftDensity / max(leftDensity(:));
rightNorm = rightDensity / max(rightDensity(:));

maxAlpha = 165; % <-- overall transparency control (0 = invisible, 255 = fully opaque)

switch mode
    case 'left'
        w = leftNorm;
        img = zeros(size(w,1), size(w,2), 4, 'uint8');
        for c = 1:3
            img(:,:,c) = uint8(blue(c) + w * (lightGreen(c) - blue(c)));
        end
        img(:,:,4) = uint8(w * maxAlpha);

    case 'right'
        w = rightNorm;
        img = zeros(size(w,1), size(w,2), 4, 'uint8');
        for c = 1:3
            img(:,:,c) = uint8(blue(c) + w * (lightGreen(c) - blue(c)));
        end
        img(:,:,4) = uint8(w * maxAlpha);

    case 'both'
        singleW = max(leftNorm, rightNorm);
        overlapW = min(leftNorm, rightNorm);

        img = zeros(size(singleW,1), size(singleW,2), 4, 'uint8');
        for c = 1:3
            base = blue(c) + singleW * (lightGreen(c) - blue(c));
            blended = base + overlapW .* (yellow(c) - base);
            img(:,:,c) = uint8(blended);
        end
        img(:,:,4) = uint8(singleW * maxAlpha);
end

tex = Screen('MakeTexture', window, img);
texCache(key) = tex;

end