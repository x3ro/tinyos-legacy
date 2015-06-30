function [ax1,ax2,ax3,ax4,bx1,bx2,bx3,bx4,ex1,ex2,ex3,ex4,fx1,fx2,fx3,fx4] = loadLinearData(plotFigures,filterMedian,filterAverage)
% [ax1,ax2,ax3,ax4,bx1,bx2,bx3,bx4,ex1,ex2,ex3,ex4,fx1,fx2,fx3,fx4] = loadLinearData(plot,filterMedian,filterAverage)
%
% This will load the best data sets for each path in the variables provided and
% calibrate this data.  Could filter the data in here as well.
% plot = 1 if you want to plot data

load A1.txt;
load B2.txt;
load E1.txt;
load F1.txt;

[ax1,ax2,ax3,ax4] = plotData(A1,plotFigures,1,'b','A1raw');
[bx1,bx2,bx3,bx4] = plotData(B2,plotFigures,2,'b','B2raw');
[ex1,ex2,ex3,ex4] = plotData(E1,plotFigures,3,'b','E1raw');
[fx1,fx2,fx3,fx4] = plotData(F1,plotFigures,4,'b','F1raw');

[p1,p2,p3,p4] = plotCalibrateData(0,plotFigures,5,'b','CalibrateData');

ax1 = [ax1(:,1), polyval(p1,ax1(:,2))];
ax2 = [ax2(:,1), polyval(p2,ax2(:,2))];
ax3 = [ax3(:,1), polyval(p3,ax3(:,2))];
ax4 = [ax4(:,1), polyval(p4,ax4(:,2))];

bx1 = [bx1(:,1), polyval(p1,bx1(:,2))];
bx2 = [bx2(:,1), polyval(p2,bx2(:,2))];
bx3 = [bx3(:,1), polyval(p3,bx3(:,2))];
bx4 = [bx4(:,1), polyval(p4,bx4(:,2))];

ex1 = [ex1(:,1), polyval(p1,ex1(:,2))];
ex2 = [ex2(:,1), polyval(p2,ex2(:,2))];
ex3 = [ex3(:,1), polyval(p3,ex3(:,2))];
ex4 = [ex4(:,1), polyval(p4,ex4(:,2))];

fx1 = [fx1(:,1), polyval(p1,fx1(:,2))];
fx2 = [fx2(:,1), polyval(p2,fx2(:,2))];
fx3 = [fx3(:,1), polyval(p3,fx3(:,2))];
fx4 = [fx4(:,1), polyval(p4,fx4(:,2))];

% Would filter the data here............................
numMedianPoints = 3;
numAveragePoints = 8;

if filterMedian == 1
    y1 = movingMedian(ax1(:,2),numMedianPoints);
    y2 = movingMedian(ax2(:,2),numMedianPoints);
    y3 = movingMedian(ax3(:,2),numMedianPoints);
    y4 = movingMedian(ax4(:,2),numMedianPoints);
    ax1(:,2) = y1;
    ax2(:,2) = y2;
    ax3(:,2) = y3;
    ax4(:,2) = y4;

    y1 = movingMedian(bx1(:,2),numMedianPoints);
    y2 = movingMedian(bx2(:,2),numMedianPoints);
    y3 = movingMedian(bx3(:,2),numMedianPoints);
    y4 = movingMedian(bx4(:,2),numMedianPoints);
    bx1(:,2) = y1;
    bx2(:,2) = y2;
    bx3(:,2) = y3;
    bx4(:,2) = y4;

    y1 = movingMedian(ex1(:,2),numMedianPoints);
    y2 = movingMedian(ex2(:,2),numMedianPoints);
    y3 = movingMedian(ex3(:,2),numMedianPoints);
    y4 = movingMedian(ex4(:,2),numMedianPoints);
    ex1(:,2) = y1;
    ex2(:,2) = y2;
    ex3(:,2) = y3;
    ex4(:,2) = y4;

    y1 = movingMedian(fx1(:,2),numMedianPoints);
    y2 = movingMedian(fx2(:,2),numMedianPoints);
    y3 = movingMedian(fx3(:,2),numMedianPoints);
    y4 = movingMedian(fx4(:,2),numMedianPoints);
    fx1(:,2) = y1;
    fx2(:,2) = y2;
    fx3(:,2) = y3;
    fx4(:,2) = y4;
end

if filterAverage == 1
    y1 = movingAverage(ax1(:,2),numAveragePoints);
    y2 = movingAverage(ax2(:,2),numAveragePoints);
    y3 = movingAverage(ax3(:,2),numAveragePoints);
    y4 = movingAverage(ax4(:,2),numAveragePoints);
    ax1(:,2) = y1;
    ax2(:,2) = y2;
    ax3(:,2) = y3;
    ax4(:,2) = y4;

    y1 = movingAverage(bx1(:,2),numAveragePoints);
    y2 = movingAverage(bx2(:,2),numAveragePoints);
    y3 = movingAverage(bx3(:,2),numAveragePoints);
    y4 = movingAverage(bx4(:,2),numAveragePoints);
    bx1(:,2) = y1;
    bx2(:,2) = y2;
    bx3(:,2) = y3;
    bx4(:,2) = y4;

    y1 = movingAverage(ex1(:,2),numAveragePoints);
    y2 = movingAverage(ex2(:,2),numAveragePoints);
    y3 = movingAverage(ex3(:,2),numAveragePoints);
    y4 = movingAverage(ex4(:,2),numAveragePoints);
    ex1(:,2) = y1;
    ex2(:,2) = y2;
    ex3(:,2) = y3;
    ex4(:,2) = y4;

    y1 = movingAverage(fx1(:,2),numAveragePoints);
    y2 = movingAverage(fx2(:,2),numAveragePoints);
    y3 = movingAverage(fx3(:,2),numAveragePoints);
    y4 = movingAverage(fx4(:,2),numAveragePoints);
    fx1(:,2) = y1;
    fx2(:,2) = y2;
    fx3(:,2) = y3;
    fx4(:,2) = y4;
end


plotNewData(ax1,ax2,ax3,ax4,plotFigures,6,'k','A1filtered');
plotNewData(bx1,bx2,bx3,bx4,plotFigures,7,'k','B2filtered');
plotNewData(ex1,ex2,ex3,ex4,plotFigures,8,'k','E1filtered');
plotNewData(fx1,fx2,fx3,fx4,plotFigures,9,'k','F1filtered');
