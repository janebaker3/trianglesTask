function handleBlockBreak(window, bl, white, frameTime, doingEyetracking, grey, dispAccuracy, accuracy)
if doingEyetracking
    Eyelink('StopRecording');
    Eyelink('Message', 'BLOCK_END');
end

switch bl
    case 1
        msg = 'End of Trial.\n\nTake a break!\n\nPress Enter when you are ready to continue.';
    case 2
        msg = 'End of Block %d.\n\nTake a break!\n\nPress Enter when you are ready to continue.';
    case 3
        msg = 'End of Task!\n\nPress Enter to exit.';
end

if ~dispAccuracy
    DrawFormattedText(window, ...
        sprintf(msg, bl), ...
        'center', 'center', white);
else
    accuracy = round(accuracy * 100);
    DrawFormattedText(window, ...
        sprintf('End of Trial.\n\nAccuracy: %d%%\n\nTake a break!\n\nPress Enter when you are ready to continue.', ...
        accuracy), ...
        'center', 'center', white);
end
Screen('Flip', window);

waitForEnter = true;
enterKey = KbName('return');
KbReleaseWait;
while waitForEnter
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && any(keyCode(enterKey))
        waitForEnter = false;
        KbReleaseWait;
    end
    WaitSecs(0.01);
end

if doingEyetracking
    Eyelink('StartRecording');
end
WaitSecs(frameTime);
end
