function clearTimerFired
%Removes old graph and log data to minimize memory overflow and allow
%matlab to run longer
global TESTDETECT

if (TESTDETECT.graphFlag)
    for ind = 1:length(TESTDETECT.motes)
        if ((length(TESTDETECT.graphPlot) >= ind) && ... 
                ishandle(TESTDETECT.graphPlot(ind)))
            xdata = get(TESTDETECT.graphPlot(ind),'XData');
            ydata = get(TESTDETECT.graphPlot(ind),'YData');
            
            % keep last 200, no negative entries
            minX = max(1,length(xdata)-200);
            minY = max(1,length(ydata)-200);
            set(TESTDETECT.graphPlot(ind),'XData',xdata(minX:end));
            set(TESTDETECT.graphPlot(ind),'YData',ydata(minY:end));
        end
    end
end

if (TESTDETECT.cleanLogFlag)
    % keep last 10000, no negative entries
    minEntry = max(1,size(MTT.reportMat,2)-10000)
    MTT.reportMat = MTT.reportMat(minEntry,end);
end