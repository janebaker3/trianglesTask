function [data, frameNum, accuracy] = runTrials(window, f, bl, frameNum, data, ...
    white, grey, green, orange, red, defTriCol, ...
    x1, x3, xOffset, yCenterTri, anglesRad, radius, isConvex, newWidth, ...
    frameTime, slack, numDistractors, H, spaceKey, stdHrz, stdVert, ...
    doingEyetracking, target, distractor, beliefGreen, stateGreen, ...
    halfDist, wideRange, givingFeedback, instructions1, instructions2, showInstruction, ...
    showAccuracy, vbl, endAudio)

KbQueueFlush();
KbQueueStart();

beliefSelection = ' ';
accuracyCounter = 0;

%% audio 
if givingFeedback
    % Make sure Psychtoolbox is properly initialized
    InitializePsychSound(1); % 1 = low latency mode

    % Sampling rate (Hz)
    freq = 44100;

    PsychPortAudio('Close');
    % Open audio device: mode 1 = playback only
    pahandle = PsychPortAudio('Open', [], 1, 1, freq, 1);

    % Create beep waveform: 500 Hz sine wave, 1 second long
    beepFreq = 250; % Hz
    duration = 1;
    t = linspace(0, duration, freq * duration);
    %waveform = sin(2 * pi * beepFreq * t);
    waveform = sin(2*pi*beepFreq*t) + 0.5*sin(2*pi*2*beepFreq*t);

    % Put into a row vector with one channel
    waveform = waveform(:)';

    % Fill audio buffer
    PsychPortAudio('FillBuffer', pahandle, waveform);

    isPlaying = false;
end

%% 
nextInst = false;
finalInst = false;
switchTime = 0;

% change states according to the hazard rate
isLeft = zeros(1, f);
isLeft(1) = rand() < 0.5;
for j = 2:f
    if rand < H
        isLeft(j) = ~isLeft(j - 1);
    else
        isLeft(j) = isLeft(j - 1);
    end
end

% set position of both triangles
if wideRange
    xCenterLeftTri = x1;
    xCenterRightTri = x3;
else
    if ~doingEyetracking %%%%%
        xCenterLeftTri = newWidth / 8;
        xCenterRightTri = 7 *(newWidth / 8);
    else
        xCenterLeftTri = xOffset - (newWidth / 3);
        xCenterRightTri = xOffset + (newWidth / 3);
    end
end

% recompute triangle position
xPosLeft  = cos(anglesRad) * radius + xCenterLeftTri;
xPosRight = cos(anglesRad) * radius + xCenterRightTri;
yPos = sin(anglesRad) * radius + yCenterTri;

% set up bounds
if halfDist || wideRange
    leftBound = xCenterLeftTri;
    rightBound = xCenterRightTri;
else
    leftBound = x1;
    rightBound = x3;
end

if showInstruction
    % go through instructions at the beginning of each block
    blockInstructions(window, instructions1, white, spaceKey, frameTime);
    if bl == 3
        next = false;
        targetX = zeros(1, 100);
        targetY = zeros(1, 100);
        for t = 1:100
            targetX(t) = getValidTargetX(xCenterLeftTri, leftBound, rightBound, stdHrz, ...
                wideRange, halfDist, xCenterLeftTri, xCenterRightTri);
            targetY(t) = normrnd(yCenterTri, stdVert);
        end

        % show demo until space is pressed

        textTop = ['This is the distribution that targets are selected\n\n' ...
            'from when the left triangle is the source.'];
        textBottom = 'Press space to continue.';

        while ~next
            % add text
            DrawFormattedText(window, textTop, 'center', 50, white);
            DrawFormattedText(window, textBottom, 'center', newHeight - 75, white);

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
                next = true;
                KbReleaseWait;
            end
        end
        WaitSecs(frameTime);
    end
    blockInstructions(window, instructions2, white, spaceKey, frameTime);
end

% get time of block starting
logEyetrackMessage(doingEyetracking, 'BLOCK_START');
blockStart = GetSecs();
data(bl).blockStartTime = blockStart;

% start the task
for i = 1:f
    % record current block and frame numbers
    frameStart = GetSecs();
    data(frameNum).blockNumber = bl;
    data(frameNum).frNumber = i;
    data(frameNum).frameStartTime = frameStart - blockStart;

    % create eyetracking msg for state switches
    if i > 1
        if isLeft(i) && ~isLeft(i - 1)
            logEyetrackMessage(doingEyetracking, 'STATE_CHANGED_TO_LEFT');
            switchTime = GetSecs();
        elseif ~isLeft(i) && isLeft(i-1)
            logEyetrackMessage(doingEyetracking, 'STATE_CHANGED_TO_RIGHT');
            switchTime = GetSecs();
        end
    end

    % set means
    if isLeft(i)
        if stateGreen == true
            Screen('FramePoly', window, green, [xPosLeft; yPos]', isConvex);
            Screen('FramePoly', window, orange, [xPosRight; yPos]', isConvex);
        end
        sourceX = xCenterLeftTri;
    else
        if stateGreen == true
            Screen('FramePoly', window, orange, [xPosLeft; yPos]', isConvex);
            Screen('FramePoly', window, green, [xPosRight; yPos]', isConvex);
        end
        sourceX = xCenterRightTri;
    end

    targetX = getValidTargetX(sourceX, leftBound, rightBound, stdHrz, ...
        wideRange, halfDist, xCenterLeftTri, xCenterRightTri);

    % record the source and target position
    targetY = normrnd(yCenterTri, stdVert);
    data(frameNum).sourceIsLeft = isLeft(i);
    data(frameNum).targetX = targetX;
    data(frameNum).targetY = targetY;

    % draw target
    DrawFormattedText(window, target, targetX, targetY, red);

    % draw distractors
    distractorPos = zeros(5, 2);
    for d = 1:numDistractors
        dx = randi([1, newWidth]);
        dy = normrnd(yCenterTri, stdVert);
        distractorPos(d, :) = [dx, dy];
        DrawFormattedText(window, distractor, dx, dy, red);
    end

    % flip screen
    if f ==1
        vbl = Screen('Flip', window);
    else
        vbl = Screen('Flip', window, vbl + frameTime - slack);
    end

    stimOnset = vbl;
    data(frameNum).stimOnset = stimOnset - blockStart;

    %KbQueueFlush([], 1); %%%%%

    % check for key presses
    [pressed, firstPress] = KbQueueCheck();
    keyPressed = ' ';
    responseTime = NaN;
    keypressTime = NaN;

    isFirst = (i == 1);


    %while GetSecs() < frameStart + frameTime
    %    [pressed, secs, keyCode] = KbCheck;

    keyIdx = find(firstPress);
    if ~isempty(keyIdx)
        keyName = KbName(keyIdx(1));
        responseTime = firstPress(keyIdx(1)) - switchTime; %stimOnset;
        keypressTime = firstPress(keyIdx(1)) - blockStart;
        if strcmpi(keyName, 'F')
            keyPressed = 'F';
            if beliefGreen
                beliefSelection = 'left';
            end
            logEyetrackMessage(doingEyetracking, 'BELIEF_IS_LEFT');
        elseif strcmpi(keyName, 'J')
            keyPressed = 'J';
            if beliefGreen
                beliefSelection = 'right';
            end
            logEyetrackMessage(doingEyetracking, 'BELIEF_IS_RIGHT');
        else
            if frameNum > 1 && ~isFirst
                keyPressed = data(frameNum - 1).keyPressed;
            end
        end
    else
        if frameNum > 1 && ~isFirst
            keyPressed = data(frameNum - 1).keyPressed;
        elseif frameNum == 1
            keyPressed = ' ';
        end
    end

    % record key presses and response time
    data(frameNum).keyPressed = keyPressed;
    data(frameNum).keypressTime = keypressTime;
    data(frameNum).responseTime = responseTime;
    data(frameNum).trialEndTime = GetSecs() - blockStart;

    % set appropriate border around triangles for block 2
    drawBlockTriangles(bl, window, beliefSelection, xPosLeft, xPosRight, ...
        yPos, green, orange, isConvex, defTriCol);

    % draw triangles
    Screen('FillPoly', window, defTriCol, [xPosLeft; yPos]', isConvex);
    Screen('FillPoly', window, defTriCol, [xPosRight; yPos]', isConvex);

    if givingFeedback
        isPlaying = genNoise(isLeft(i), keyPressed, isPlaying, 0, pahandle);
    end

    if (data(frameNum).keyPressed == 'F' && data(frameNum).sourceIsLeft) || ...
            (data(frameNum).keyPressed == 'J' && ~data(frameNum).sourceIsLeft)
        accuracyCounter = accuracyCounter + 1;
    end

    % control the length of trials
    frameNum = frameNum + 1;
end
KbQueueStop();

accuracy = accuracyCounter / f;

if endAudio
    isPlaying = genNoise(0, 'J', isPlaying, 1, pahandle);
end

handleBlockBreak(window, bl, white, frameTime, doingEyetracking, grey, ...
    showAccuracy, accuracy);

%% Save data
save('myResult.mat', 'data');
end
