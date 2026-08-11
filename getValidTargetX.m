function tx = getValidTargetX(sourceX, leftBound, rightBound, stdHrz, ...
    xCenterLeft, ~)

if sourceX == xCenterLeft
    direction = +1;
else
    direction = -1;
end
tx = sourceX + abs(normrnd(0, stdHrz)) * direction;
while tx < leftBound || tx > rightBound
    tx = sourceX + abs(normrnd(0, stdHrz)) * direction;
end
end