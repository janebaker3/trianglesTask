function blockInstructions(window, message, white, spaceKey, frameTime)
    confirmed = false;
    while ~confirmed
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(spaceKey)
            confirmed = true;
            KbReleaseWait;
        end
        DrawFormattedText(window, message, 'center', 'center' , white);
        Screen('Flip', window);
        WaitSecs(frameTime);
    end
end


