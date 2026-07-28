function drawDist(sourceX, leftBound, rightBound, stdHrz, xCenterLeft, xCenterRight, ...
    window, textTop, textBottom, white, newHeight, defTriCol, xPosLeft, xPosRight, ...
    yPos, isConvex, red, spaceKey, yCenterTri, stdVert, frameTime)

stopDemo = false; % indicates when to move on

targetX = zeros(1, 100);
targetY = zeros(1, 100);
for t = 1:100
    targetX(t) = getValidTargetX(sourceX, leftBound, rightBound, stdHrz, ...
        xCenterLeft, xCenterRight);
    targetY(t) = normrnd(yCenterTri, stdVert);
end

if sourceX == xCenterLeft
    distMode = 'left';
else
    distMode = 'right';
end

while ~stopDemo
    tex = getDistributionTexture(window, 'both', stdHrz, stdVert, ...
        xCenterLeft, xCenterRight, yCenterTri, leftBound, rightBound, newHeight);
    Screen('DrawTexture', window, tex, [], [leftBound, 0, rightBound, newHeight]);

    % add text
    DrawFormattedText(window, textTop, 'center', 50, white);
    DrawFormattedText(window, textBottom, 'center', newHeight - 125, white);

    % draw triangles
    Screen('FillPoly', window, defTriCol, [xPosLeft; yPos]', isConvex);
    Screen('FillPoly', window, defTriCol, [xPosRight; yPos]', isConvex);

    % draw targets
    for t = 1:100
        DrawFormattedText(window, 'T', targetX(t), targetY(t), red);
    end
    Screen('Flip', window);

    % check for keypress and switch to right demo when space is pressed
    [keyIsdown, ~, keyCode] = KbCheck;
    if keyIsdown && keyCode(spaceKey)
        stopDemo = true;
        KbReleaseWait;
    end
end
WaitSecs(frameTime);

end