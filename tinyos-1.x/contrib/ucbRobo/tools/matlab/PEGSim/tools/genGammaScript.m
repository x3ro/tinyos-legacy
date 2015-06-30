% Sample Script.
% Generates plots for the function gamma, which is a plot of the
% probability of connecting to a node given a static routing tree

close all;
load('nodes10','SN10');
%SN10 = genSN10;
plotExSN(SN10,[1 1 1 0 1]);

resolution = 0.5;
tic;
if ~exist('Gamma')
    Gamma = calcGamma(SN10,resolution);
end
toc;
% 1 is original position
% 2:4 are positions nearby 1st position
% 5 is far away position
EPos = [2 9 2 3 2 1;
        2 5 3 2 1 2];
% Graph at position 1
figure(2);
for i = 1:2
    subplot(1,2,i);
    [X Y] = meshgrid(0:resolution:SN10.dimX,0:resolution:SN10.dimY);
    %transpose because mesh takes x as columns, y as rows
    Z = squeeze(Gamma(:,:,EPos(1,i)/resolution,EPos(2,i)/resolution))';
    mesh(X,Y,Z);
    hold on;
    axis_vals = axis; % want to plot above 3d plot.
    plot3(EPos(1,i),EPos(2,i),axis_vals(end),'*k','markersize',10);
    title(sprintf('Connection Probability with 0 retransmission.\nEvader Position is at (%d,%d)',EPos(1,i),EPos(2,i)));
    xlabel('x-axis');
    ylabel('y-axis');
    set(gcf,'Position',[520 680,1120 420]);
    hold off;
end

% Graph at position 2:5
figure(3);
for i = 3:6
    subplot(2,2,i-2)
    [X Y] = meshgrid(0:resolution:SN10.dimX,0:resolution:SN10.dimY);
    Z = squeeze(Gamma(:,:,EPos(1,i)/resolution,EPos(2,i)/resolution))';
    mesh(X,Y,Z);
    hold on;
    axis_vals = axis; % want to plot above 3d plot.
    plot3(EPos(1,i),EPos(2,i),axis_vals(end),'*k','markersize',10);
    title(sprintf('Connection Probability with 0 retransmission.\nEvader Position is at (%d,%d)',EPos(1,i),EPos(2,i)));
    xlabel('x-axis');
    ylabel('y-axis');
    hold off;
end
