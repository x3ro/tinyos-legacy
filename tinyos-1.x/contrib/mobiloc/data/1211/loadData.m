function [ax1,ax2,ax3,ax4,bx1,bx2,bx3,bx4,cx1,cx2,cx3,cx4,dx1,dx2,dx3,dx4] = loadData(plotFigures,filterMedian,filterAverage)
% [ax1,ax2,ax3,ax4,bx1,bx2,bx3,bx4,cx1,cx2,cx3,cx4,dx1,dx2,dx3,dx4] = loadData(plot,filterMedian,filterAverage)
%
% This will load the best data sets for each path in the variables provided and
% calibrate this data.  Could filter the data in here as well.
% plot = 1 if you want to plot data

load A1.txt;
load B2.txt;
load C2.txt;
load D1.txt;

[ax1,ax2,ax3,ax4] = plotData(A1,plotFigures,1,'b','A1raw');
[bx1,bx2,bx3,bx4] = plotData(B2,plotFigures,2,'b','B2raw');
[cx1,cx2,cx3,cx4] = plotData(C2,plotFigures,3,'b','C2raw');
[dx1,dx2,dx3,dx4] = plotData(D1,plotFigures,4,'b','D1raw');

[p1,p2,p3,p4] = plotCalibrateData(0,plotFigures,5,'b','CalibrateData');

ax1 = [ax1(:,1), polyval(p1,ax1(:,2))];
ax2 = [ax2(:,1), polyval(p2,ax2(:,2))];
ax3 = [ax3(:,1), polyval(p3,ax3(:,2))];
ax4 = [ax4(:,1), polyval(p4,ax4(:,2))];

bx1 = [bx1(:,1), polyval(p1,bx1(:,2))];
bx2 = [bx2(:,1), polyval(p2,bx2(:,2))];
bx3 = [bx3(:,1), polyval(p3,bx3(:,2))];
bx4 = [bx4(:,1), polyval(p4,bx4(:,2))];

cx1 = [cx1(:,1), polyval(p1,cx1(:,2))];
cx2 = [cx2(:,1), polyval(p2,cx2(:,2))];
cx3 = [cx3(:,1), polyval(p3,cx3(:,2))];
cx4 = [cx4(:,1), polyval(p4,cx4(:,2))];

dx1 = [dx1(:,1), polyval(p1,dx1(:,2))];
dx2 = [dx2(:,1), polyval(p2,dx2(:,2))];
dx3 = [dx3(:,1), polyval(p3,dx3(:,2))];
dx4 = [dx4(:,1), polyval(p4,dx4(:,2))];

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

    y1 = movingMedian(cx1(:,2),numMedianPoints);
    y2 = movingMedian(cx2(:,2),numMedianPoints);
    y3 = movingMedian(cx3(:,2),numMedianPoints);
    y4 = movingMedian(cx4(:,2),numMedianPoints);
    cx1(:,2) = y1;
    cx2(:,2) = y2;
    cx3(:,2) = y3;
    cx4(:,2) = y4;

    y1 = movingMedian(dx1(:,2),numMedianPoints);
    y2 = movingMedian(dx2(:,2),numMedianPoints);
    y3 = movingMedian(dx3(:,2),numMedianPoints);
    y4 = movingMedian(dx4(:,2),numMedianPoints);
    dx1(:,2) = y1;
    dx2(:,2) = y2;
    dx3(:,2) = y3;
    dx4(:,2) = y4;
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

    y1 = movingAverage(cx1(:,2),numAveragePoints);
    y2 = movingAverage(cx2(:,2),numAveragePoints);
    y3 = movingAverage(cx3(:,2),numAveragePoints);
    y4 = movingAverage(cx4(:,2),numAveragePoints);
    cx1(:,2) = y1;
    cx2(:,2) = y2;
    cx3(:,2) = y3;
    cx4(:,2) = y4;

    y1 = movingAverage(dx1(:,2),numAveragePoints);
    y2 = movingAverage(dx2(:,2),numAveragePoints);
    y3 = movingAverage(dx3(:,2),numAveragePoints);
    y4 = movingAverage(dx4(:,2),numAveragePoints);
    dx1(:,2) = y1;
    dx2(:,2) = y2;
    dx3(:,2) = y3;
    dx4(:,2) = y4;
end


plotNewData(ax1,ax2,ax3,ax4,plotFigures,6,'k','A1filtered');
plotNewData(bx1,bx2,bx3,bx4,plotFigures,7,'k','B2filtered');
plotNewData(cx1,cx2,cx3,cx4,plotFigures,8,'k','C2filtered');
plotNewData(dx1,dx2,dx3,dx4,plotFigures,9,'k','D1filtered');
