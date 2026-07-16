




% smaller triangles
% less vert std
% proportionally scale standard deviation based on how many standard
% deviations the means change


%{
put instructions that "motion" of t from left to right is irrelevant
%}

%% Setup
sca;
close all;
clear;
clc;

warning('off', 'all');
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'VisualDebugLevel', 3);
Snd('Close')
smuPath = 'C:/Users/mattLab/Brown Dropbox/Matthew Nassar/ALP_Summer2022/sharedMatlabUtilities/eeglab2024.2.1';
addpath(genpath(smuPath));

% set up eyetracking
doingEyetracking = 1; 
halfDist = 1;
wideRange = 0;

if doingEyetracking 
    cd('C:/Users/mattLab/Downloads/task/task') % need to update this 
    ioObject = io64;
    LPT1address = hex2dec('3FB8');
    status = io64(ioObject);
    eyeFileName = 'p4';
    warning('off', 'all');
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 1);

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

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, ...
    [xOffset, yOffset, xOffset + newWidth, yOffset + newHeight]);

ifi = Screen('GetFlipInterval', window);
slack = ifi / 2;

vbl = Screen('Flip', window);

KbQueueCreate();

% more eyetracking setup
if doingEyetracking 
    % Initialize Eyelink with window-specific defaults FIRST
    el = EyelinkInitDefaults(window);

    % Fill and flip the screen to make sure it's visible to the Eyelink host
    Screen('FillRect', window, el.backgroundcolour);
    Screen('Flip', window);

    % Initialize Eyelink connection
    if ~EyelinkInit()
        fprintf('Eyelink Init failed.\n');
        return;
    end

    % Open the EDF file
    status = Eyelink('OpenFile', eyeFileName);
    if status ~= 0
        fprintf('Failed to open EDF file.\n');
        return;
    end

    % Set up tracker configuration
    Eyelink('Command', 'screen_pixel_coords = 0 0 %d %d', ScreenXpixels - 1, screenYpixels - 1);
    Eyelink('Command', 'calibration_type = HV9');
    Eyelink('Command', 'generate_default_targets = YES');
    disp('5');

    % Force tracker into setup mode (optional)
    Eyelink('StartSetup');
    WaitSecs(0.5);

    % Launch the tracker setup (calibration, validation, etc.)
    EyelinkDoTrackerSetup(el);
    Eyelink('StartRecording');


 %{
    [el] = EyelinkSetup(1,window)
    Eyelink('Openfile', eyeFileName);
    Eyelink('StartRecording');
    io64(ioObject,LPT1address,1); %Trigger example 1
    WaitSecs(0.01)
    io64(ioObject,LPT1address,0);
    % define windowRect if needed

 %}

end

% define the centers of the window
[xCenter, yCenter] = RectCenter(windowRect);
%ifi = Screen('GetFlipInterval', window);

%% Triangle Setup
% define triangle parameters
numSides = 3;
anglesDeg = linspace(270, 630, numSides + 1);
anglesRad = anglesDeg * (pi / 180);
radius = 15;
baseSep = 0.5 * newWidth;
baseMult = 1.5;

% define relevant x values
x0 = xCenter - (3 * (newWidth/4)); % one quarter to the left of window edge
x1 = xCenter - (2 * (newWidth/4)); % left window edge
x3 = xCenter + (2 * (newWidth/4)); % right window edge

% set position of both triangles
if wideRange
    xCenterLeftTri = x1;
    xCenterRightTri = x3;
else                                                     
    if doingEyetracking %%%%%
        xCenterLeftTri = newWidth / 8;
        xCenterRightTri = 7 *(newWidth / 8);
    else
        xCenterLeftTri = xOffset - (newWidth / 3);
        xCenterRightTri = xOffset + (newWidth / 3 );
    end
end

% randomly generate 10000 integers in the range that the target should
% appear most when left triangle is source
numListLeft = randi([round(x1), round(x3)], 1, 10000);
diff = xCenterRightTri - xCenterLeftTri;
multiplier = baseMult * (diff/baseSep);

% use this for the horizontal standard deviation
stdHrz = newWidth/5.5; %285; % std(numListLeft) * multiplier; ---- 1000 for big screen
% /6 for easier, /4 for harder
stdVert = newHeight / 36;

data(1).std = stdHrz;
data(1).centers = xCenterLeftTri;
data(2).centers = xCenterRightTri;

yCenterTri = yCenter;
xPosLeft = cos(anglesRad) * radius + xCenterLeftTri;
xPosRight = cos(anglesRad) * radius + xCenterRightTri;
yPos = sin(anglesRad) * radius + yCenterTri;
isConvex = 1;

%% frame Setup
numBlk = 3; % blocks
numFr = 6000; % frames (should be 12000)
H = 0.003; % hazard rate
frameTime = 0.05; % length of each frame (seconds)

% set up target and distractor text
target = 'T';
distractor = 'L';
numDistractors = 20;
Screen('TextFont', window, 'Arial');

% set up bounds
if halfDist || wideRange
    leftBound = xCenterLeftTri;
    rightBound = xCenterRightTri;
else
    leftBound = x1;
    rightBound = x3;
end

% set up keypress
KbName('UnifyKeyNames');
leftKey = KbName('F');
rightKey = KbName('J');
spaceKey = KbName('space');

instructions(window, newWidth, newHeight, xCenterLeftTri, xCenterRightTri, yCenterTri, ...
    stdHrz, stdVert, xPosLeft, xPosRight, yPos, isConvex, frameTime, spaceKey, ...
    leftBound, rightBound, wideRange, halfDist);

%% Main Loop
% initialize frame number per block
frameNum = 1;

showInstruction = 1;
showAccuracy = 0;
endAudio = 0;

for bl = 1:numBlk

    % define parameters that change throughout blocks
    switch bl
        case 1
            % state lights up
            training = true;
            stateGreen = false;
            beliefGreen = true;
            halfDist = 1;
            wideRange = 0;
            iterations = 3;
            f = 2400;
            stdHrz = newWidth/5.5;
            instructions1 = ['In this first block, the triangle that is\n\n' ...
                'currently generating the target will have a green outline.\n\n' ...
                'The target itself will be red like the distractors, so you\n\n' ...
                'should still try to locate it based on which triangle is the\n\n' ...
                'source. This will help you get familiar with the task. Press\n\n' ...
                'space to continue.'];
            instructions2 = ['If you believe the **left** triangle is generating the\n\n' ...
                'target, press the ''F'' key once. If you believe the **right**\n\n' ...
                'triangle is generating the target, press the ''J'' key once.\n\n' ...
                'You may do this as many times as you feel are necessary\n\n' ...
                'throughout the task. You do not need to hold keys. As mentioned\n\n' ...
                'before, the triangle outlined in green is the source, so you \n\n' ...
                'should press ''F'' when the left triangle is outlined and ''J'' \n\n' ...
                'when the right triangle is outlined. Press space to begin.'];
        case 2
            % belief lights up
            stateGreen = false;
            beliefGreen = true;
            halfDist = 1;
            wideRange = 0;
            iterations = 1;
            f = numFr;
            stdHrz = newWidth/5.5;
            instructions1 = ['This block is identical to the final segment of the\n\n' ...
                'training block. You will not be told your accuracy at the end\n\n' ...
                'of the trial. Everything else remains the same.\n\n' ...
                'Press space to continue.'];
            instructions2 = ['Reminder: If you believe the **left** triangle is\n\n' ...
                'generating the target, press the ''F'' key once. If you believe\n\n' ...
                'the **right** triangle is generating the target, press the\n\n' ...
                '''J'' key ONCE. You may do this as many times as you feel are\n\n' ...
                'necessary throughout the task. You do not need to hold keys.\n\n' ...
                'This will last five minutes. Press space to begin.'];
        case 3
            % neither lights up
            stateGreen = false;
            beliefGreen = true;
            halfDist = 1;
            wideRange = 0;
            iterations = 1;
            f = numFr;
            stdHrz = newWidth/4;
            instructions1 = ['This final block is similar to the previous \n\n' ...
                'one. However, each source has a wider area that the target\n\n' ...
                'may generate in now. Press space to see an example of how\n\n' ...
                'this distribution may look when the left triangle is the source.'];
            instructions2 = ['Reminder: If you believe the **left** triangle is\n\n' ...
                'generating the target, press the ''F'' key once. If you believe\n\n' ...
                'the **right** triangle is generating the target, press the\n\n' ...
                '''J'' key once. You may do this as many times as you feel are\n\n' ...
                'necessary throughout the task. You do not need to hold keys.\n\n' ...
                'This will last five minutes. Press space to begin.'];
    end

    if bl == 1
        [data, frameNum, accuracyData] = trainingBlock(window, f, bl, frameNum, data, ...
            white, grey, green, orange, red, defTriCol, x1, x3, xOffset, yCenterTri, ...
            anglesRad, radius, isConvex, newWidth, newHeight, frameTime, slack, numDistractors, ...
            H, spaceKey, stdHrz, stdVert, doingEyetracking, target, distractor, ...
            beliefGreen, stateGreen, halfDist, wideRange, vbl);
    else
        givingFeedback = 0;
        [data, frameNum, accuracy] = runTrials(window, f, bl, frameNum, data, ...
            white, grey, green, orange, red, defTriCol, x1, x3, xOffset, yCenterTri, ...
            anglesRad, radius, isConvex, newWidth, newHeight, frameTime, slack, numDistractors, ...
            H, spaceKey, stdHrz, stdVert, doingEyetracking, target, distractor, ...
            beliefGreen, stateGreen, halfDist, wideRange, givingFeedback, instructions1, ...
            instructions2, showInstruction, showAccuracy, vbl, endAudio);
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