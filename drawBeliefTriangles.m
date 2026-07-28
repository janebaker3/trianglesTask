function drawBeliefTriangles(window, beliefSelection, xPosLeft, xPosRight, yPos, green, orange, isConvex, defTriCol)
    if strcmp(beliefSelection, 'left')
        Screen('FramePoly', window, green, [xPosLeft; yPos]', 2);
        Screen('FramePoly', window, orange, [xPosRight; yPos]', 2);
    elseif strcmp(beliefSelection, 'right')
        Screen('FramePoly', window, orange, [xPosLeft; yPos]', 2);
        Screen('FramePoly', window, green, [xPosRight; yPos]', 2);
    else
        Screen('FramePoly', window, orange, [xPosLeft; yPos]', 2);
        Screen('FramePoly', window, orange, [xPosRight; yPos]', 2);
    end
    Screen('FillPoly', window, defTriCol, [xPosLeft; yPos]', 2);
    Screen('FillPoly', window, defTriCol, [xPosRight; yPos]', 2);
end