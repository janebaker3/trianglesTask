function [isPlaying] = genNoise(isLeft, keyPressed, isPlaying, trainingOver, ...
    pahandle)

%% condition to play beep
if ((isLeft && keyPressed ~= 'F') || (~isLeft && keyPressed ~= 'J')) ...
        && ~isPlaying

    % play beep
    PsychPortAudio('Start', pahandle, 0, 0, 1);
    isPlaying = true;
elseif ((isLeft && keyPressed == 'F') || (~isLeft && keyPressed == 'J')) ...
        && isPlaying
    PsychPortAudio('Stop', pahandle, 1);
    isPlaying = false;
end

if trainingOver
    if isPlaying
        PsychPortAudio('Stop', pahandle, 1);
    end
    PsychPortAudio('Close', pahandle);
end

end



    %{
pahandle → the audio device we opened.

0 → number of repetitions (infinite repitions).

0 → when to start (0 = immediately).

1 → whether to block until it actually starts (waits 
until playback has begun before returning).
    %}