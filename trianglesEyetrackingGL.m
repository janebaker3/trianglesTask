%% Setup
sca;
close all;
clear;
clear functions
clc;

warning('off', 'all');
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'VisualDebugLevel', 3);

% set up eyetracking
doingEyetracking = 0;

if doingEyetracking 
    cd('C:\Users\jigol\Desktop\newTaskVersion')
    eyeFileName = 'stuff.edf';
    warning('off', 'all');
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 0);
    %Eyelink('Initialize');

    % DEBUGGING
    if ~EyelinkInit()
        fprintf('Eyelink failed to initialize.\n');
        sca;
        return;
    end
end

screens = Screen('Screens');
screenNumber = max(screens);

% define colors
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
defTriCol = white / 1.5;
red = [255 0 0];
green = [0 255 0];
orange = [255 165 0];

% set up window size
[ScreenXpixels, screenYpixels] = Screen('WindowSize', screenNumber);
if doingEyetracking %%%%%
    newWidth = round(ScreenXpixels);
    newHeight = round(screenYpixels);
    xOffset = 0;
    yOffset = 0;
else
    newWidth = round(ScreenXpixels / 2);
    newHeight = round(screenYpixels / 2);
    xOffset = round(ScreenXpixels / 4);
    yOffset = round(screenYpixels / 4);
end

% define window
if ~doingEyetracking
    Screen('Preference', 'SkipSyncTests', 1);
end

blue = [125 125 200];
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, blue, ...
    [xOffset, yOffset, xOffset + newWidth, yOffset + newHeight]);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %

ifi = Screen('GetFlipInterval', window);
slack = ifi / 2;

vbl = Screen('Flip', window);

KbQueueCreate();

% more eyetracking setup
if doingEyetracking
    el = EyelinkInitDefaults(window);
    Screen('FillRect', window, el.backgroundcolour);
    Screen('Flip', window);

    result = EyelinkInit();
    fprintf('EyelinkInit() returned: %d\n', result);
    fprintf('IsConnected after Init: %d\n', Eyelink('IsConnected'));

    if result ~= 1
        fprintf('Eyelink Init failed — aborting.\n');
        sca;
        return;
    end

    status = Eyelink('OpenFile', eyeFileName);
    fprintf('OpenFile status: %d\n', status);
    if status ~= 0
        fprintf('Failed to open EDF file.\n');
        sca;
        return;
    end

    Eyelink('Command', 'screen_pixel_coords = 0 0 %d %d', ScreenXpixels - 1, screenYpixels - 1);
    Eyelink('Command', 'calibration_type = HV9');
    Eyelink('Command', 'generate_default_targets = YES');

    fprintf('IsConnected before DoTrackerSetup: %d\n', Eyelink('IsConnected'));

    EyelinkDoTrackerSetup(el);

    fprintf('IsConnected after DoTrackerSetup: %d\n', Eyelink('IsConnected'));

    err = Eyelink('CheckRecording');
    fprintf('CheckRecording before StartRecording: %d\n', err);

    status = Eyelink('StartRecording');
    fprintf('StartRecording status: %d\n', status);

    if status ~= 0
        fprintf('Eyelink error message: %s\n', Eyelink('CommandResult'));
        fprintf('Last error: %s\n', Eyelink('GetLastError'));
    end
end

% define the centers of the window
[xCenter, yCenter] = RectCenter(windowRect);

%% Triangle Setup
% define triangle parameters
numSides = 3;
anglesDeg = linspace(270, 630, numSides + 1);
anglesRad = anglesDeg * (pi / 180);
radius = 15;

% define relevant x values
x1 = xCenter - (2 * (newWidth/4)); % left window edge
x3 = xCenter + (2 * (newWidth/4)); % right window edge

% set position of both triangles
if doingEyetracking %%%%%
    xCenterLeft = newWidth / 8;
    xCenterRight = 7 *(newWidth / 8);
else
    xCenterLeft = xOffset - (newWidth / 3);
    xCenterRight = xOffset + (newWidth / 3 );
end

sep = xCenterRight - xCenterLeft;

% use this for the horizontal standard deviation
% index 1 = Easy, index 2 = Medium, index 3 = Hard
stdHrz = sep ./ [3.0, 1.8, 1.2]; 
stdVert = newHeight / 36;

data(1).centers = xCenterLeft;
data(2).centers = xCenterRight;

yCenterTri = yCenter;
xPosLeft = cos(anglesRad) * radius + xCenterLeft;
xPosRight = cos(anglesRad) * radius + xCenterRight;
yPos = sin(anglesRad) * radius + yCenterTri;
isConvex = 1;

%% frame Setup
numMainBlocks = 6; % 3 difficulty levels x 2 hazard rates
frameTime = 0.05; % length of each frame (seconds)

numFrTraining = round(120 / frameTime); % 2 minutes per training trial
numFrMain = round(180 / frameTime); % 3 minutes per main block

% hazard rate: index 1 = Less Frequent, index 2 = Frequent
Hs = [0.003, 0.01];

% set up target and distractor text
target = 'T';
distractor = 'L';
numDistractors = 20;
Screen('TextFont', window, 'Arial');

leftBound = xCenterLeft;
rightBound = xCenterRight;

% set up keypress
KbName('UnifyKeyNames');
leftKey = KbName('F');
rightKey = KbName('J');
spaceKey = KbName('space');

instructions(window, newWidth, newHeight, xCenterLeft, xCenterRight, yCenterTri, ...
    stdHrz(1), stdVert, xPosLeft, xPosRight, yPos, isConvex, frameTime, spaceKey, ...
    leftBound, rightBound);

%% Main Loop
% initialize frame number across the whole session
frameNum = 1;

showInstruction = 1;
showAccuracy = 0;
endAudio = 0;

%% ---- Training block (bl = 1): Easy difficulty, Less Frequent hazard ----
bl = 1;
trainStdIdx = 1; % Easy
trainHazIdx = 1; % Less Frequent
H = Hs(trainHazIdx);
trainStdHrz = stdHrz(trainStdIdx);

[data, frameNum, accuracyData] = trainingBlock(window, numFrTraining, bl, frameNum, data, ...
    white, grey, green, orange, red, defTriCol, x1, x3, xOffset, yCenterTri, ...
    anglesRad, radius, isConvex, newWidth, newHeight, frameTime, slack, numDistractors, ...
    H, spaceKey, trainStdHrz, trainStdIdx, trainHazIdx, stdVert, doingEyetracking, target, distractor, vbl, ...
    xCenterLeft, xCenterRight, leftBound, rightBound, xPosLeft, xPosRight, yPos, numMainBlocks);

%% ---- Explain difficulty levels and switching-frequency framing ----
explainDifficultyAndHazard(window, stdHrz, xCenterLeft, xCenterRight, leftBound, rightBound, ...
    yCenterTri, stdVert, xPosLeft, xPosRight, yPos, isConvex, defTriCol, red, white, spaceKey, ...
    frameTime, newHeight);

%% ---- Build randomized order of the 6 main blocks ----
% combos: column 1 = std index (1 Easy, 2 Medium, 3 Hard)
%         column 2 = hazard index (1 Less Frequent, 2 Frequent)
combos = zeros(numMainBlocks, 2);
c = 1;
for s = 1:length(stdHrz)
    for hz = 1:length(Hs)
        combos(c, :) = [s, hz];
        c = c + 1;
    end
end

isHard = combos(:, 1) == length(stdHrz); % hardest difficulty index
nonHardIdx = find(~isHard);

firstComboIdx = nonHardIdx(randi(length(nonHardIdx)));
remainingComboIdx = setdiff(1:numMainBlocks, firstComboIdx);
remainingComboIdx = remainingComboIdx(randperm(length(remainingComboIdx)));
blockOrder = [firstComboIdx, remainingComboIdx];

diffLabels = {'Easy', 'Medium', 'Hard'};
hazLabels = {'Less Frequent', 'Frequent'};

%% ---- Run the 6 main blocks ----
for mb = 1:numMainBlocks
    bl = mb + 1;
    comboIdx = blockOrder(mb);
    stdIdx = combos(comboIdx, 1);
    hazIdx = combos(comboIdx, 2);

    H = Hs(hazIdx);
    currStdHrz = stdHrz(stdIdx);

    diffLabel = diffLabels{stdIdx};
    hazLabel = hazLabels{hazIdx};

    instructions1 = sprintf(['This is the beginning of Block %d of %d.\n\n' ...
        'In this block, the difficulty level is **%s** and the source will\n\n' ...
        'switch at the **%s** rate.\n\n' ...
        'Press space to continue.'], mb, numMainBlocks, diffLabel, hazLabel);

    instructions2 = ['Reminder: If you believe the **left** triangle is\n\n' ...
        'generating the target, press the ''F'' key once. If you believe\n\n' ...
        'the **right** triangle is generating the target, press the\n\n' ...
        '''J'' key once. You may do this as many times as you feel are\n\n' ...
        'necessary throughout the task. You do not need to hold keys.\n\n' ...
        'This will last three minutes. Press space to begin.'];

    givingFeedback = 0;
    [data, frameNum, accuracy] = runTrials(window, numFrMain, bl, mb, numMainBlocks, frameNum, data, ...
        white, grey, green, orange, red, defTriCol, x1, x3, xOffset, yCenterTri, ...
        anglesRad, radius, isConvex, newWidth, newHeight, frameTime, slack, numDistractors, ...
        H, spaceKey, currStdHrz, stdIdx, hazIdx, stdVert, doingEyetracking, target, distractor, ...
        givingFeedback, instructions1, instructions2, showInstruction, ...
        showAccuracy, vbl, endAudio, xCenterLeft, xCenterRight, leftBound, ...
        rightBound, xPosLeft, xPosRight, yPos);
end

if doingEyetracking
    Eyelink('StopRecording');
    Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
    Eyelink('Command', 'clear_screen 0'); % Clear Host PC backdrop graphics at the end of the experiment
    WaitSecs(0.5); % Allow some time before closing and transferring file
    Eyelink('CloseFile');
end
%% Close
sca;
KbQueueRelease();
%% Save Eye Data
if doingEyetracking
    try
        fprintf('Receiving data file ''%s''\n', eyeFileName );
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(eyeFileName, 'file')
            fprintf('Data file ''%s'' can be found here: ''%s''\n', eyeFileName, 'C:Users/mattLab/Documents/JanePupil');
            system(['edf2asc ' eyeFileName]);
        end
    catch rdf
        fprintf('Problem receiving data file ''%s''\n', eyeFileName );
        rdf;
    end
    [el] = EyelinkSetup(0,window);
end

warning('off', 'all');
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'VisualDebugLevel', 3);