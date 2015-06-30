function [x1,x2,x3,x4] = plotData(x,plotFigures,figurenum,color,pictureName)
% [x1,x2,x3,x4] = plotData(x,plot,figurenum,color,pictureName)
%
% Plots the data given in x in the form
% moteID, seqNo, range
% plot = 1 if want to plot

xnew = sortrows(x,1);
xnewcol1 = xnew(:,1);

i = find(xnewcol1 == 1);
x1 = xnew(min(i):max(i),2:3);

i = find(xnewcol1 == 2);
x2 = xnew(min(i):max(i),2:3);

i = find(xnewcol1 == 3);
x3 = xnew(min(i):max(i),2:3);

i = find(xnewcol1 == 4);
x4 = xnew(min(i):max(i),2:3);

% Filter the data
A = [1];
B = ones(1,8)*0.125;
y1 = filter(B,A,x1(:,2),[x1(1:4,2); zeros(3,1)]);
y2 = filter(B,A,x2(:,2),[x2(1:4,2); zeros(3,1)]);
y3 = filter(B,A,x3(:,2),[x3(1:4,2); zeros(3,1)]);
y4 = filter(B,A,x4(:,2),[x4(1:4,2); zeros(3,1)]);
%x1(:,2) = y1;
%x2(:,2) = y2;
%x3(:,2) = y3;
%x4(:,2) = y4;

if plotFigures == 1
    figure(figurenum)

    subplot(2,2,1),
    plot(x1(:,1),x1(:,2),color,'LineWidth',2);
    title('Range Estimation from Node 1 to Target','fontWeight','bold');
    xlabel('Sample Number (4 Hz sample rate)');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');

    subplot(2,2,2),
    plot(x2(:,1),x2(:,2),color,'LineWidth',2);
    title('Range Estimation from Node 2 to Target','fontWeight','bold');
    xlabel('Sample Number (4 Hz sample rate)');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');

    subplot(2,2,3),
    plot(x3(:,1),x3(:,2),color,'LineWidth',2);
    title('Range Estimation from Node 3 to Target','fontWeight','bold');
    xlabel('Sample Number (4 Hz sample rate)');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');

    subplot(2,2,4),
    plot(x4(:,1),x4(:,2),color,'LineWidth',2);
    title('Range Estimation from Node 4 to Target','fontWeight','bold');
    xlabel('Sample Number (4 Hz sample rate)');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    
    print('-dpng', pictureName);
    print('-depsc', pictureName);
end

