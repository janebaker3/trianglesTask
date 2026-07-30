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

blue = [0 0 255];
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
numBlk = 3; % blocks
numFr = 6000; % frames (should be 12000)
Hs = [0.003, 0.003, 0.01]; % hazard rate (switch every 17s, switch every 5s
frameTime = 0.05; % length of each frame (seconds)

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
% initialize frame number per block
frameNum = 1;

showInstruction = 1;
showAccuracy = 0;
endAudio = 0;

for bl = 1:numBlk
    H = Hs(bl);

    % define parameters that change throughout blocks
    switch bl
        case 1
            training = true;
            iterations = 3;
            f = 60;%2400;
            instructions1 = 'Not used';
            instructions2 = 'Not used';
        case 2
            iterations = 1;
            f = numFr;
            showDist = 1;
            instructions1 = ['This is the beginning of the task. You previously saw one of the\n\n' ...
                'distributions that the target can be generated from. Now, the\n\n' ...
                'distribution will switch among three possible distributions\n\n' ...
                'Throughout the task. Everything else remains the same. \n\n' ...
                'Press space to see these distributions.'];
            instructions2 = ['Reminder: If you believe the **left** triangle is\n\n' ...
                'generating the target, press the ''F'' key once. If you believe\n\n' ...
                'the **right** triangle is generating the target, press the\n\n' ...
                '''J'' key ONCE. You may do this as many times as you feel are\n\n' ...
                'necessary throughout the task. You do not need to hold keys.\n\n' ...
                'This will last five minutes. Press space to begin.'];
        case 3
            iterations = 1;
            f = numFr;
            showDist = 0;
            instructions1 = ['This final block is similar to the previous \n\n' ...
                'one. However, the source will switch more often than it\n\n' ...
                'did previously. Press space to continue.'];
            instructions2 = ['Reminder: If you believe the **left** triangle is\n\n' ...
                'generating the target, press the ''F'' key once. If you believe\n\n' ...
                'the **right** triangle is generating the target, press the\n\n' ...
                '''J'' key once. You may do this as many times as you feel are\n\n' ...
                'necessary throughout the task. You do not need to hold keys.\n\n' ...
                'This will last five minutes. Press space to begin.'];
    end

    if bl == 1
        continue    
        [data, frameNum, accuracyData] = trainingBlock(window, f, bl, frameNum, data, ...
            white, grey, green, orange, red, defTriCol, x1, x3, xOffset, yCenterTri, ...
            anglesRad, radius, isConvex, newWidth, newHeight, frameTime, slack, numDistractors, ...
            H, spaceKey, stdHrz, stdVert, doingEyetracking, target, distractor, vbl, ...
            xCenterLeft, xCenterRight, leftBound, rightBound, xPosLeft, xPosRight, yPos);
    else
        givingFeedback = 0;
        [data, frameNum, accuracy] = runTrials(window, f, bl, frameNum, data, ...
            white, grey, green, orange, red, defTriCol, showDist, x1, x3, xOffset, yCenterTri, ...
            anglesRad, radius, isConvex, newWidth, newHeight, frameTime, slack, numDistractors, ...
            H, spaceKey, stdHrz, stdVert, doingEyetracking, target, distractor, ...
            givingFeedback, instructions1, instructions2, showInstruction, ...
            showAccuracy, vbl, endAudio, xCenterLeft, xCenterRight, leftBound, ...
            rightBound, xPosLeft, xPosRight, yPos);
    end
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