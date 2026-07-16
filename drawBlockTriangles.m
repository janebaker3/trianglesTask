function drawBlockTriangles(bl, window, beliefSelection, xPosLeft, xPosRight, yPos, green, orange, isConvex, defTriCol)
    switch bl
        case 1
            drawBeliefTriangles(window, beliefSelection, xPosLeft, ...
                xPosRight, yPos, green, orange, isConvex, defTriCol);
        case 2
            drawBeliefTriangles(window, beliefSelection, xPosLeft, ...
                xPosRight, yPos, green, orange, isConvex, defTriCol);
            % Screen('FramePoly', window, orange, [xPosLeft; yPos]', isConvex);
            % Screen('FramePoly', window, orange, [xPosRight; yPos]', isConvex);
        case 3
            drawBeliefTriangles(window, beliefSelection, xPosLeft, ...
                xPosRight, yPos, green, orange, isConvex, defTriCol);
    end
end
