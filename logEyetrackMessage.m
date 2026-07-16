function logEyetrackMessage(doingEyetracking, msg)
    if doingEyetracking
        Eyelink('Message', msg);
    end
end