function [data, frameNum, accuracy] = runTrials(window, f, bl, frameNum, data, ...
    white, grey, green, orange, red, defTriCol, ...
    x1, x3, xOffset, yCenterTri, anglesRad, radius, isConvex, newWidth, ...
    frameTime, slack, numDistractors, H, spaceKey, stdHrz, stdVert, ...
    doingEyetracking, target, distractor,givingFeedback, instructions1, ...
    instructions2, showInstruction, showAccuracy, vbl, endAudio, ...
    xCenterLeft, xCenterRight, leftBound, rightBound, xPosLeft, xPosRight, yPos)

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

sourceX = zeros(1, f);
sourceX(isLeft) = xCenterLeft;
sourceX(~isLeft) = xCenterRight;

if showInstruction
    % go through instructions at the beginning of each block
    blockInstructions(window, instructions1, white, spaceKey, frameTime);
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

    targetX = getValidTargetX(sourceX(f), leftBound, rightBound, stdHrz, ...
        wideRange, halfDist, xCenterLeft, xCenterRight);

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
    if f == 1
        vbl = Screen('Flip', window);
    else
        vbl = Screen('Flip', window, vbl + frameTime - slack);
    end

    stimOnset = vbl;
    data(frameNum).stimOnset = stimOnset - blockStart;

    % check for key presses
    [pressed, firstPress] = KbQueueCheck();
    keyPressed = ' ';
    responseTime = NaN;
    keypressTime = NaN;

    isFirst = (i == 1);

    keyIdx = find(firstPress);
    if ~isempty(keyIdx)
        keyName = KbName(keyIdx(1));
        responseTime = firstPress(keyIdx(1)) - switchTime;
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

    % set appropriate border around triangles
    drawBeliefTriangles(window, beliefSelection, xPosLeft, ...
                xPosRight, yPos, green, orange, isConvex, defTriCol);

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
