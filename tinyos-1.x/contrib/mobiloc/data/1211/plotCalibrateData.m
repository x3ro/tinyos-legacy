function [p1,p2,p3,p4] = plotCalibrateData(meanFilter,plotFigures,fignum,color,figname)
% [p1,p2,p3,p4] = plotCalibrateData(meanFilter,plot,fignum,,color)
%
% Plot Calibration Data for Mote1
% if mean == 1, plot the mean, otherwise use the median
% plot = 1 to plot

if plotFigures == 1
    figure(fignum)
end

cal10cm = load('calibrate1\10cm.txt');
cal20cm = load('calibrate1\20cm.txt');
cal30cm = load('calibrate1\30cm.txt');
cal40cm = load('calibrate1\40cm.txt');
cal50cm = load('calibrate1\50cm.txt');
cal60cm = load('calibrate1\60cm.txt');
cal70cm = load('calibrate1\70cm.txt');
cal80cm = load('calibrate1\80cm.txt');
cal90cm = load('calibrate1\90cm.txt');
cal100cm = load('calibrate1\100cm.txt');
cal110cm = load('calibrate1\110cm.txt');
cal120cm = load('calibrate1\120cm.txt');
cal130cm = load('calibrate1\130cm.txt');
cal140cm = load('calibrate1\140cm.txt');

x = 100:100:1400;
if meanFilter == 0
    y1 = [median(cal10cm(:,3)) median(cal20cm(:,3)) median(cal30cm(:,3)) median(cal40cm(:,3)) median(cal50cm(:,3)) median(cal60cm(:,3)) median(cal70cm(:,3)) median(cal80cm(:,3)) median(cal90cm(:,3)) median(cal100cm(:,3)) median(cal110cm(:,3)) median(cal120cm(:,3)) median(cal130cm(:,3)) median(cal140cm(:,3))];
else
    y1 = [mean(cal10cm(:,3)) mean(cal20cm(:,3)) mean(cal30cm(:,3)) mean(cal40cm(:,3)) mean(cal50cm(:,3)) mean(cal60cm(:,3)) mean(cal70cm(:,3)) mean(cal80cm(:,3)) mean(cal90cm(:,3)) mean(cal100cm(:,3)) mean(cal110cm(:,3)) mean(cal120cm(:,3)) mean(cal130cm(:,3)) mean(cal140cm(:,3))];
end

% Find slope and offset
p1 = polyfit(y1,x,1);

if plotFigures == 1
    subplot(2,2,1),
    hold on;
    plot(x,y1,color,'LineWidth',2);
    plot(x,x,'k','LineWidth',2);
    plot(x,polyval(p1,y1),'g','LineWidth',2);
    title(['Node 1: m=' num2str(p1(1)) ',b=' num2str(p1(2))],'fontWeight','bold');
    xlabel('True Distance (mm)');
    ylabel('Measured Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;
end

cal10cm = load('calibrate2\10cm.txt');
cal20cm = load('calibrate2\20cm.txt');
cal30cm = load('calibrate2\30cm.txt');
cal40cm = load('calibrate2\40cm.txt');
cal50cm = load('calibrate2\50cm.txt');
cal60cm = load('calibrate2\60cm.txt');
cal70cm = load('calibrate2\70cm.txt');
cal80cm = load('calibrate2\80cm.txt');
cal90cm = load('calibrate2\90cm.txt');
cal100cm = load('calibrate2\100cm.txt');
cal110cm = load('calibrate2\110cm.txt');
cal120cm = load('calibrate2\120cm.txt');
cal130cm = load('calibrate2\130cm.txt');
cal140cm = load('calibrate2\140cm.txt');

x = 100:100:1400;
if meanFilter == 0
    y2 = [median(cal10cm(:,3)) median(cal20cm(:,3)) median(cal30cm(:,3)) median(cal40cm(:,3)) median(cal50cm(:,3)) median(cal60cm(:,3)) median(cal70cm(:,3)) median(cal80cm(:,3)) median(cal90cm(:,3)) median(cal100cm(:,3)) median(cal110cm(:,3)) median(cal120cm(:,3)) median(cal130cm(:,3)) median(cal140cm(:,3))];
else
    y2 = [mean(cal10cm(:,3)) mean(cal20cm(:,3)) mean(cal30cm(:,3)) mean(cal40cm(:,3)) mean(cal50cm(:,3)) mean(cal60cm(:,3)) mean(cal70cm(:,3)) mean(cal80cm(:,3)) mean(cal90cm(:,3)) mean(cal100cm(:,3)) mean(cal110cm(:,3)) mean(cal120cm(:,3)) mean(cal130cm(:,3)) mean(cal140cm(:,3))];
end

% Find slope and offset
p2 = polyfit(y2,x,1);

if plotFigures == 1
    subplot(2,2,2),
    hold on;
    plot(x,y2,color,'LineWidth',2);
    plot(x,x,'k','LineWidth',2);
    plot(x,polyval(p2,y2),'g','LineWidth',2);
    title(['Node 2: m=' num2str(p2(1)) ',b='num2str(p2(2))],'fontWeight','bold');
    xlabel('True Distance (mm)');
    ylabel('Measured Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;
end

cal10cm = load('calibrate3\10cm.txt');
cal20cm = load('calibrate3\20cm.txt');
cal30cm = load('calibrate3\30cm.txt');
cal40cm = load('calibrate3\40cm.txt');
cal50cm = load('calibrate3\50cm.txt');
cal60cm = load('calibrate3\60cm.txt');
cal70cm = load('calibrate3\70cm.txt');
cal80cm = load('calibrate3\80cm.txt');
cal90cm = load('calibrate3\90cm.txt');
cal100cm = load('calibrate3\100cm.txt');
cal110cm = load('calibrate3\110cm.txt');
cal120cm = load('calibrate3\120cm.txt');
cal130cm = load('calibrate3\130cm.txt');
cal140cm = load('calibrate3\140cm.txt');

x = 100:100:1400;
if meanFilter == 0
    y3 = [median(cal10cm(:,3)) median(cal20cm(:,3)) median(cal30cm(:,3)) median(cal40cm(:,3)) median(cal50cm(:,3)) median(cal60cm(:,3)) median(cal70cm(:,3)) median(cal80cm(:,3)) median(cal90cm(:,3)) median(cal100cm(:,3)) median(cal110cm(:,3)) median(cal120cm(:,3)) median(cal130cm(:,3)) median(cal140cm(:,3))];
else
    y3 = [mean(cal10cm(:,3)) mean(cal20cm(:,3)) mean(cal30cm(:,3)) mean(cal40cm(:,3)) mean(cal50cm(:,3)) mean(cal60cm(:,3)) mean(cal70cm(:,3)) mean(cal80cm(:,3)) mean(cal90cm(:,3)) mean(cal100cm(:,3)) mean(cal110cm(:,3)) mean(cal120cm(:,3)) mean(cal130cm(:,3)) mean(cal140cm(:,3))];
end

% Find slope and offset
p3 = polyfit(y3,x,1);

if plotFigures == 1
    subplot(2,2,3),
    hold on;
    plot(x,y3,color,'LineWidth',2);
    plot(x,x,'k','LineWidth',2);
    plot(x,polyval(p3,y3),'g','LineWidth',2);
    title(['Node 3: m=' num2str(p3(1)) ',b='num2str(p3(2))],'fontWeight','bold');
    xlabel('True Distance (mm)');
    ylabel('Measured Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;
end

cal10cm = load('calibrate4\10cm.txt');
cal20cm = load('calibrate4\20cm.txt');
cal30cm = load('calibrate4\30cm.txt');
cal40cm = load('calibrate4\40cm.txt');
cal50cm = load('calibrate4\50cm.txt');
cal60cm = load('calibrate4\60cm.txt');
cal70cm = load('calibrate4\70cm.txt');
cal80cm = load('calibrate4\80cm.txt');
cal90cm = load('calibrate4\90cm.txt');
cal100cm = load('calibrate4\100cm.txt');
cal110cm = load('calibrate4\110cm.txt');
cal120cm = load('calibrate4\120cm.txt');
cal130cm = load('calibrate4\130cm.txt');
cal140cm = load('calibrate4\140cm.txt');

x = 100:100:1400;
if meanFilter == 0
    y4 = [median(cal10cm(:,3)) median(cal20cm(:,3)) median(cal30cm(:,3)) median(cal40cm(:,3)) median(cal50cm(:,3)) median(cal60cm(:,3)) median(cal70cm(:,3)) median(cal80cm(:,3)) median(cal90cm(:,3)) median(cal100cm(:,3)) median(cal110cm(:,3)) median(cal120cm(:,3)) median(cal130cm(:,3)) median(cal140cm(:,3))];
else
    y4 = [mean(cal10cm(:,3)) mean(cal20cm(:,3)) mean(cal30cm(:,3)) mean(cal40cm(:,3)) mean(cal50cm(:,3)) mean(cal60cm(:,3)) mean(cal70cm(:,3)) mean(cal80cm(:,3)) mean(cal90cm(:,3)) mean(cal100cm(:,3)) mean(cal110cm(:,3)) mean(cal120cm(:,3)) mean(cal130cm(:,3)) mean(cal140cm(:,3))];
end

% Find slope and offset
p4 = polyfit(y4,x,1);

if plotFigures == 1
    subplot(2,2,4),
    hold on;
    plot(x,y4,color,'LineWidth',2);
    plot(x,x,'k','LineWidth',2);
    plot(x,polyval(p4,y4),'g','LineWidth',2);
    title(['Node 4: m=' num2str(p4(1)) ',b='num2str(p4(2))],'fontWeight','bold');
    xlabel('True Distance (mm)');
    ylabel('Measured Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;
    
    print('-dpng', figname);
    print('-depsc', figname);
end

