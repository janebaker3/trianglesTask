function drawBeliefTriangles(window, beliefSelection, xPosLeft, xPosRight, yPos, green, orange, isConvex, defTriCol)
    black = [0 0 0];

    if strcmp(beliefSelection, 'left')
        leftColor = green; rightColor = orange;
    elseif strcmp(beliefSelection, 'right')
        leftColor = orange; rightColor = green;
    else
        leftColor = orange; rightColor = orange;
    end

    % black outline first (slightly thicker)
    Screen('FramePoly', window, black, [xPosLeft; yPos]', 4);
    Screen('FramePoly', window, black, [xPosRight; yPos]', 4);

    % colored indicator on top (thinner, sits inside the black border)
    Screen('FramePoly', window, leftColor, [xPosLeft; yPos]', 2);
    Screen('FramePoly', window, rightColor, [xPosRight; yPos]', 2);

    Screen('FillPoly', window, defTriCol, [xPosLeft; yPos]', isConvex);
    Screen('FillPoly', window, defTriCol, [xPosRight; yPos]', isConvex);
end