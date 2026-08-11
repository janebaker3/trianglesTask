function instructions(window, newWidth, newHeight, xCenterLeft, xCenterRight, ...
    yCenterTri, stdHrz, stdVert, xPosLeft, xPosRight, yPos, ...
    isConvex, frameTime, spaceKey, leftBound, rightBound)

white = [255 255 255];
defTriCol = white / 1.5;
red = [255 0 0];
green = [0 255 0];

%% instructions block
% welcome
welcomeText = 'Welcome to the triangles task!';
DrawFormattedText(window, welcomeText, 'center', 'center', white);
Screen('Flip', window);
WaitSecs(3);

% general instructions
nextDemo = false;
instructions = ['In this task, you will be indicating which of two triangles\n\n' ...
    'you think that a target is coming from. The target is a red T. There\n\n' ...
    'will also be many red Ls that are there as distractors. Both the target\n\n' ...
    'and the distractors will have a new position every 50 milliseconds.\n\n' ...
    'The position of the distractors are random and the position of the\n\n' ...
    'target is determined by which triangle is the source. Press space to\n\n' ...
    'see a demonstration of how targets are generated from a triangle.'];

% show the instructions until spacebar is pressed
while ~nextDemo
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(spaceKey)
        nextDemo = true;
        KbReleaseWait;
    end
    DrawFormattedText(window, instructions, 'center', 'center' , white);
    Screen('Flip', window);
    WaitSecs(0.05);
end

%% source demonstration
% show demo until space is pressed
textTop = ['This is a distribution that targets are selected\n\n' ...
    'from when the left triangle is the source. It may appear\n\n' ...
    'that the target is ''moving'' in a specific direction\n\n' ...
    'during the task, but this is a result of how frequently\n\n' ...
    'a new position is selected.'];
textBottom = ['A new target position is selected from this\n\n ' ...
    'distribution every frame (every 50 milliseconds). \n\n' ...
    'Press space to continue.'];

drawDist(xCenterLeft, leftBound, rightBound, stdHrz, xCenterLeft, xCenterRight, ...
    window, textTop, textBottom, white, newHeight, defTriCol, xPosLeft, xPosRight, ...
    yPos, isConvex, red, spaceKey, yCenterTri, stdVert, frameTime)

% define text to appear
textTop = ['This is an example of how the target will be generated\n\nwhen' ...
    ' the left triangle is the source. Press space to continue.'];
textBottom = ['**Note that the triangle and the T are' ...
    ' green for\n\ndemonstration purposes.**'];

rightDemo = false;
demoOver = false;

while ~rightDemo
    tex = getDistributionTexture(window, 'both', stdHrz, stdVert, ...
        xCenterLeft, xCenterRight, yCenterTri, leftBound, rightBound, newHeight);
    Screen('DrawTexture', window, tex, [], [leftBound, 0, rightBound, newHeight]);

    % add text
    DrawFormattedText(window, textTop, 'center', 50, white);
    DrawFormattedText(window, textBottom, 'center', newHeight - 75, white);

    % draw triangles
    Screen('FillPoly', window, green, [xPosLeft; yPos]', isConvex);
    Screen('FillPoly', window, defTriCol, [xPosRight; yPos]', isConvex);

    % draw target
    targetX = getValidTargetX(xCenterLeft, leftBound, rightBound, stdHrz, ...
        xCenterLeft, xCenterRight);
    targetY = normrnd(yCenterTri, stdVert);
    DrawFormattedText(window, 'T', targetX, targetY, green);

    % draw distractors
    for d = 1:20
        dx = randi([1, newWidth]);
        dy = normrnd(yCenterTri, stdVert);
        DrawFormattedText(window, 'L', dx, dy, red);
    end
    Screen('Flip', window);

    % check for keypress and switch to right demo when space is pressed
    [keyIsdown, ~, keyCode] = KbCheck;
    if keyIsdown && keyCode(spaceKey)
        rightDemo = true;
        KbReleaseWait;
    end
    WaitSecs(frameTime);
end

% define new text to appear
textTop = ['This is a distribution that targets are selected\n\n' ...
    'from when the right triangle is the source. It may appear\n\n' ...
    'that the target is ''moving'' in a specific direction\n\n' ...
    'during the task, but this is a result of how frequently\n\n' ...
    'a new position is selected.'];
textBottom = ['A new target position is selected from this\n\n ' ...
    'distribution every frame (every 50 milliseconds). \n\n' ...
    'Press space to continue.'];

drawDist(xCenterRight, leftBound, rightBound, stdHrz, xCenterLeft, xCenterRight, ...
    window, textTop, textBottom, white, newHeight, defTriCol, xPosLeft, xPosRight, ...
    yPos, isConvex, red, spaceKey, yCenterTri, stdVert, frameTime)

textTop = ['This is an example of how the target will be generated\n\nwhen' ...
    ' the right triangle is the source. Press space to continue.'];
textBottom = ['**Note that the triangle and the T are' ...
    ' green for\n\ndemonstration purposes.**'];

% show right demo until space is pressed
while ~demoOver
    tex = getDistributionTexture(window, 'both', stdHrz, stdVert, ...
        xCenterLeft, xCenterRight, yCenterTri, leftBound, rightBound, newHeight);
    Screen('DrawTexture', window, tex, [], [leftBound, 0, rightBound, newHeight]);

    % add text
    DrawFormattedText(window, textTop, 'center', 50, white);
    DrawFormattedText(window, textBottom, 'center', newHeight - 75, white);

    % draw triangles
    Screen('FillPoly', window, defTriCol, [xPosLeft; yPos]', isConvex);
    Screen('FillPoly', window, green, [xPosRight; yPos]', isConvex);

    % draw target
    targetX = getValidTargetX(xCenterRight, leftBound, rightBound, stdHrz, ...
        xCenterLeft, xCenterRight);
    targetY = normrnd(yCenterTri, stdVert);
    DrawFormattedText(window, 'T', targetX, targetY, green);

    % draw distractors
    for d = 1:20
        dx = randi([1, newWidth]);
        dy = normrnd(yCenterTri, stdVert);
        DrawFormattedText(window, 'L', dx, dy, red);
    end
    Screen('Flip', window);

    % check for keypress and switch to right demo when space is pressed
    [keyIsdown, ~, keyCode] = KbCheck;
    if keyIsdown && keyCode(spaceKey)
        demoOver = true;
        KbReleaseWait;
    end
    WaitSecs(frameTime);
end

end