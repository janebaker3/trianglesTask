function tx = getValidTargetX(sourceX, leftBound, rightBound, stdHrz, ...
                                wideRange, halfDist, xCenterLeft, ~)
if wideRange || halfDist
    if sourceX == xCenterLeft
        direction = +1; 
    else
        direction = -1; 
    end
    tx = sourceX + abs(normrnd(0, stdHrz)) * direction;
    while tx < leftBound || tx > rightBound
        tx = sourceX + abs(normrnd(0, stdHrz)) * direction;
    end
elseif ~halfDist && ~wideRange
    tx = normrnd(sourceX, stdHrz);
    while tx < leftBound || tx > rightBound
        tx = normrnd(sourceX, stdHrz);
    end
end
