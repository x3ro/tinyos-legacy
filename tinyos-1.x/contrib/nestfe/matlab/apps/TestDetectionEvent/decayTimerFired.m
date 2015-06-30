function decayTimerFired
%Reduces the edge width of nodes that have not been recently updated
global TESTDETECT

% get/set the proper line element for moteID

if (TESTDETECT.drawFlag)
    for ind = 1:length(TESTDETECT.motes)
        if ((length(TESTDETECT.drawPlot) >= ind) && ...
                ishandle(TESTDETECT.drawPlot(ind)) && ...
                ishandle(TESTDETECT.drawLabelPlot(ind)))
            lwidth = get(TESTDETECT.drawPlot(ind),'LineWidth');
            lwidth = max(1,lwidth-1);
            set(TESTDETECT.drawPlot(ind),'LineWidth',lwidth);
            myPos = get(TESTDETECT.drawPlot(ind),'Position');
            myPos(3:4) = max([1 1],myPos(3:4)-1);
            set(TESTDETECT.drawPlot(ind),'Position',myPos);
        end
    end
end
