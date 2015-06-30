function [k1,k2,k3,k4] = plotCalibrationData(plotFigures,fignum,figname,histfigname)

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

% Find slope and offset
x = 100:100:1400;
y1 = [median(cal10cm(:,3)) median(cal20cm(:,3)) median(cal30cm(:,3)) median(cal40cm(:,3)) median(cal50cm(:,3)) median(cal60cm(:,3)) median(cal70cm(:,3)) median(cal80cm(:,3)) median(cal90cm(:,3)) median(cal100cm(:,3)) median(cal110cm(:,3)) median(cal120cm(:,3)) median(cal130cm(:,3)) median(cal140cm(:,3))];
p1 = polyfit(y1,x,1);
y = y1;
% Plot data - median
node1 = [cal10cm(:,3)-y(1)*ones(size(cal10cm(:,3)));
    cal20cm(:,3)-y(2)*ones(size(cal20cm(:,3)));
    cal30cm(:,3)-y(3)*ones(size(cal30cm(:,3)));
    cal40cm(:,3)-y(4)*ones(size(cal40cm(:,3)));
    cal50cm(:,3)-y(5)*ones(size(cal50cm(:,3)));
    cal60cm(:,3)-y(6)*ones(size(cal60cm(:,3)));
    cal70cm(:,3)-y(7)*ones(size(cal70cm(:,3)));
    cal80cm(:,3)-y(8)*ones(size(cal80cm(:,3)));
    cal90cm(:,3)-y(9)*ones(size(cal90cm(:,3)));
    cal100cm(:,3)-y(10)*ones(size(cal100cm(:,3)));
    cal110cm(:,3)-y(11)*ones(size(cal110cm(:,3)));
    cal120cm(:,3)-y(12)*ones(size(cal120cm(:,3)));
    cal130cm(:,3)-y(13)*ones(size(cal130cm(:,3)));
    cal140cm(:,3)-y(14)*ones(size(cal140cm(:,3)))];

node160 = cal60cm(:,3)-y(6);

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

% Find slope and offset
y2 = [median(cal10cm(:,3)) median(cal20cm(:,3)) median(cal30cm(:,3)) median(cal40cm(:,3)) median(cal50cm(:,3)) median(cal60cm(:,3)) median(cal70cm(:,3)) median(cal80cm(:,3)) median(cal90cm(:,3)) median(cal100cm(:,3)) median(cal110cm(:,3)) median(cal120cm(:,3)) median(cal130cm(:,3)) median(cal140cm(:,3))];
p2 = polyfit(y2,x,1);
y = y2;
% Plot data - median
node2 = [cal10cm(:,3)-y(1)*ones(size(cal10cm(:,3)));
    cal20cm(:,3)-y(2)*ones(size(cal20cm(:,3)));
    cal30cm(:,3)-y(3)*ones(size(cal30cm(:,3)));
    cal40cm(:,3)-y(4)*ones(size(cal40cm(:,3)));
    cal50cm(:,3)-y(5)*ones(size(cal50cm(:,3)));
    cal60cm(:,3)-y(6)*ones(size(cal60cm(:,3)));
    cal70cm(:,3)-y(7)*ones(size(cal70cm(:,3)));
    cal80cm(:,3)-y(8)*ones(size(cal80cm(:,3)));
    cal90cm(:,3)-y(9)*ones(size(cal90cm(:,3)));
    cal100cm(:,3)-y(10)*ones(size(cal100cm(:,3)));
    cal110cm(:,3)-y(11)*ones(size(cal110cm(:,3)));
    cal120cm(:,3)-y(12)*ones(size(cal120cm(:,3)));
    cal130cm(:,3)-y(13)*ones(size(cal130cm(:,3)));
    cal140cm(:,3)-y(14)*ones(size(cal140cm(:,3)))];

node260 = cal60cm(:,3)-y(6);

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

% Find slope and offset
y3 = [median(cal10cm(:,3)) median(cal20cm(:,3)) median(cal30cm(:,3)) median(cal40cm(:,3)) median(cal50cm(:,3)) median(cal60cm(:,3)) median(cal70cm(:,3)) median(cal80cm(:,3)) median(cal90cm(:,3)) median(cal100cm(:,3)) median(cal110cm(:,3)) median(cal120cm(:,3)) median(cal130cm(:,3)) median(cal140cm(:,3))];
p3 = polyfit(y3,x,1);
y = y3;
% Plot data - median
node3 = [cal10cm(:,3)-y(1)*ones(size(cal10cm(:,3)));
    cal20cm(:,3)-y(2)*ones(size(cal20cm(:,3)));
    cal30cm(:,3)-y(3)*ones(size(cal30cm(:,3)));
    cal40cm(:,3)-y(4)*ones(size(cal40cm(:,3)));
    cal50cm(:,3)-y(5)*ones(size(cal50cm(:,3)));
    cal60cm(:,3)-y(6)*ones(size(cal60cm(:,3)));
    cal70cm(:,3)-y(7)*ones(size(cal70cm(:,3)));
    cal80cm(:,3)-y(8)*ones(size(cal80cm(:,3)));
    cal90cm(:,3)-y(9)*ones(size(cal90cm(:,3)));
    cal100cm(:,3)-y(10)*ones(size(cal100cm(:,3)));
    cal110cm(:,3)-y(11)*ones(size(cal110cm(:,3)));
    cal120cm(:,3)-y(12)*ones(size(cal120cm(:,3)));
    cal130cm(:,3)-y(13)*ones(size(cal130cm(:,3)));
    cal140cm(:,3)-y(14)*ones(size(cal140cm(:,3)))];

node360 = cal60cm(:,3)-y(6);

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

% Find slope and offset
y4 = [median(cal10cm(:,3)) median(cal20cm(:,3)) median(cal30cm(:,3)) median(cal40cm(:,3)) median(cal50cm(:,3)) median(cal60cm(:,3)) median(cal70cm(:,3)) median(cal80cm(:,3)) median(cal90cm(:,3)) median(cal100cm(:,3)) median(cal110cm(:,3)) median(cal120cm(:,3)) median(cal130cm(:,3)) median(cal140cm(:,3))];
p4 = polyfit(y4,x,1);
y = y4;
% Plot data - median
node4 = [cal10cm(:,3)-y(1)*ones(size(cal10cm(:,3)));
    cal20cm(:,3)-y(2)*ones(size(cal20cm(:,3)));
    cal30cm(:,3)-y(3)*ones(size(cal30cm(:,3)));
    cal40cm(:,3)-y(4)*ones(size(cal40cm(:,3)));
    cal50cm(:,3)-y(5)*ones(size(cal50cm(:,3)));
    cal60cm(:,3)-y(6)*ones(size(cal60cm(:,3)));
    cal70cm(:,3)-y(7)*ones(size(cal70cm(:,3)));
    cal80cm(:,3)-y(8)*ones(size(cal80cm(:,3)));
    cal90cm(:,3)-y(9)*ones(size(cal90cm(:,3)));
    cal100cm(:,3)-y(10)*ones(size(cal100cm(:,3)));
    cal110cm(:,3)-y(11)*ones(size(cal110cm(:,3)));
    cal120cm(:,3)-y(12)*ones(size(cal120cm(:,3)));
    cal130cm(:,3)-y(13)*ones(size(cal130cm(:,3)));
    cal140cm(:,3)-y(14)*ones(size(cal140cm(:,3)))];

node460 = cal60cm(:,3)-y(6);

% Kurtosis(x)
k1 = kurtosis(node160,0);
k2 = kurtosis(node260,0);
k3 = kurtosis(node360,0);
k4 = kurtosis(node460,0);

if plotFigures == 1
    figure(fignum)

    subplot(2,2,1),
    hold on;
    x = 1:1:length(node1);
    plot(x,node1,'k','LineWidth',2);
    plot(x,zeros(size(x)),'r:','LineWidth',2);
    title('Node 1 Calibration Data (Data - Median)','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Measured Distance (mm)','fontWeight','bold');
    axis square;
    axis([0 length(node1) -50 50]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,2,2),
    hold on;
    x = 1:1:length(node2);
    plot(x,node2,'k','LineWidth',2);
    plot(x,zeros(size(x)),'r:','LineWidth',2);
    title('Node 2 Calibration Data (Data - Median)','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Measured Distance (mm)','fontWeight','bold');
    axis square;
    axis([0 length(node2) -50 50]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,2,3),
    hold on;
    x = 1:1:length(node3);
    plot(x,node3,'k','LineWidth',2);
    plot(x,zeros(size(x)),'r:','LineWidth',2);
    title('Node 3 Calibration Data (Data - Median)','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Measured Distance (mm)','fontWeight','bold');
    axis square;
    axis([0 length(node3) -50 50]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,2,4),
    hold on;
    x = 1:1:length(node4);
    plot(x,node4,'k','LineWidth',2);
    plot(x,zeros(size(x)),'r:','LineWidth',2);
    title('Node 4 Calibration Data (Data - Median)','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Measured Distance (mm)','fontWeight','bold');
    axis square;
    axis([0 length(node4) -50 50]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;
    
    print('-dpng', figname);
    print('-depsc', figname);
    
    figure(fignum+1)
    
    edges = [-60,-50,-40,-30,-20,-10,0,10,20,30,40,50,60];
    subplot(2,2,1),
    n = histc(node1,edges);
    bar(edges,n,'histc');
    title('Node 1 Error Distribution','fontWeight','bold');
    xlabel('Distance (mm)');
    axis square;
    ticklabels = get(gca,'XTickLabels');
    ticklabels(2,:) = '   '; ticklabels(3,:) = '   '; ticklabels(4,:) = '   '; 
    ticklabels(6,:) = '   '; ticklabels(7,:) = '   '; ticklabels(8,:) = '   '; 
    ticklabels(10,:) = '   '; ticklabels(11,:) = '   '; ticklabels(12,:) = '   '; 
    set(gca,'XTickLabels',ticklabels,'fontWeight','bold');
    set(gca,'LineWidth',2,'fontWeight','bold');
    
    subplot(2,2,2),
    n = histc(node2,edges);
    bar(edges,n,'histc');
    title('Node 2 Error Distribution','fontWeight','bold');
    xlabel('Distance (mm)');
    axis square;
    ticklabels = get(gca,'XTickLabels');
    ticklabels(2,:) = '   '; ticklabels(3,:) = '   '; ticklabels(4,:) = '   '; 
    ticklabels(6,:) = '   '; ticklabels(7,:) = '   '; ticklabels(8,:) = '   '; 
    ticklabels(10,:) = '   '; ticklabels(11,:) = '   '; ticklabels(12,:) = '   '; 
    set(gca,'XTickLabels',ticklabels,'fontWeight','bold');
    set(gca,'LineWidth',2,'fontWeight','bold');

    subplot(2,2,3),
    n = histc(node3,edges);
    bar(edges,n,'histc');
    title('Node 3 Error Distribution','fontWeight','bold');
    xlabel('Distance (mm)');
    axis square;
    ticklabels = get(gca,'XTickLabels');
    ticklabels(2,:) = '   '; ticklabels(3,:) = '   '; ticklabels(4,:) = '   '; 
    ticklabels(6,:) = '   '; ticklabels(7,:) = '   '; ticklabels(8,:) = '   '; 
    ticklabels(10,:) = '   '; ticklabels(11,:) = '   '; ticklabels(12,:) = '   '; 
    set(gca,'XTickLabels',ticklabels,'fontWeight','bold');
    set(gca,'LineWidth',2,'fontWeight','bold');

    subplot(2,2,4),
    n = histc(node4,edges);
    bar(edges,n,'histc');
    title('Node 4 Error Distribution','fontWeight','bold');
    xlabel('Distance (mm)');
    ticklabels = get(gca,'XTickLabels');
    ticklabels(2,:) = '   '; ticklabels(3,:) = '   '; ticklabels(4,:) = '   '; 
    ticklabels(6,:) = '   '; ticklabels(7,:) = '   '; ticklabels(8,:) = '   '; 
    ticklabels(10,:) = '   '; ticklabels(11,:) = '   '; ticklabels(12,:) = '   '; 
    set(gca,'XTickLabels',ticklabels,'fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');

    print('-dpng', histfigname);
    print('-depsc', histfigname);
    

end
