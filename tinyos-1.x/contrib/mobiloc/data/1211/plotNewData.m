function plotNewData(x1,x2,x3,x4,plotFigures,figurenum,color,pictureName)
% plotNewData(x1,x2,x3,x4,plot,figurenum,color,pictureName)
%
% Plots the data given in x in the form
% plot = 1 if want to plot

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

