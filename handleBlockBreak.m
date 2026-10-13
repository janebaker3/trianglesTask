function handleBlockBreak(window, bl, mb, numMainBlocks, white, frameTime, doingEyetracking, grey, dispAccuracy, accuracy)
if doingEyetracking
    % Eyelink('StopRecording'); %% dont stop recording in matt's lab
    Eyelink('Message', 'BLOCK_END');
end

if bl == 1
    msg = 'End of Trial.\n\nTake a break!\n\nPress Enter when you are ready to continue.';
elseif mb == numMainBlocks
    msg = 'End of Task!\n\nPress Enter to exit.';
else
    msg = sprintf('End of Block %d of %d.\n\nTake a break!\n\nPress Enter when you are ready to continue.', ...
        mb, numMainBlocks);
end

if ~dispAccuracy
    DrawFormattedText(window, msg, 'center', 'center', white);
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

% if doingEyetracking
%     Eyelink('StartRecording');
% end
WaitSecs(frameTime);
end