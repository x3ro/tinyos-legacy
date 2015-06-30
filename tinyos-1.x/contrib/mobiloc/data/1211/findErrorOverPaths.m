function  [error1,error2,error3] = findErrorOverPaths(plotFig,fignum,plotName,ad1,ad2,ad3,ad4,bd1,bd2,bd3,bd4,cd1,cd2,cd3,cd4,dd1,dd2,dd3,dd4,ed1,ed2,ed3,ed4,fd1,fd2,fd3,fd4)
% error = findDistanceErrors(plotBar,ad1,ad2,ad3,ad4,bd1,bd2,bd3,bd4,cd1,cd2,cd3,cd4,dd1,dd2,dd3,dd4,ed1,ed2,ed3,ed4,fd1,fd2,fd3,fd4)
%
% 
dtrue = [0 700 900 1140; 700 0 1140 900; 900 1140 0 700; 1140 900 700 0];

% Start with minimum error -- CPA in
error1(1) = sum(sum((dtrue-ad1).^2))/12/10^2;
% Start with sum error after path A
error2(1) = sum(sum((dtrue-ad3).^2))/12/10^2;
% Start with diff error after path A
error3(1) = sum(sum((dtrue-ad4).^2))/12/10^2;

ad1
ad3
ad4

% Look at first two paths: A and B
d = zeros(4,4);
d(1,2) = median([ad1(1,2),ad2(1,2),bd1(1,2),bd2(1,2)]);
d(2,1) = median([ad1(1,2),ad2(1,2),bd1(1,2),bd2(1,2)]);
d(1,3) = median([ad1(1,3),ad2(1,3),bd1(1,3),bd2(1,3)]);
d(3,1) = median([ad1(1,3),ad2(1,3),bd1(1,3),bd2(1,3)]);
d(1,4) = median([ad1(1,4),ad2(1,4),bd1(1,4),bd2(1,4)]);
d(4,1) = median([ad1(1,4),ad2(1,4),bd1(1,4),bd2(1,4)]);
d(2,3) = median([ad1(2,3),ad2(2,3),bd1(2,3),bd2(2,3)]);
d(3,2) = median([ad1(2,3),ad2(2,3),bd1(2,3),bd2(2,3)]);
d(2,4) = median([ad1(2,4),ad2(2,4),bd1(2,4),bd2(2,4)]);
d(4,2) = median([ad1(2,4),ad2(2,4),bd1(2,4),bd2(2,4)]);
d(3,4) = median([ad1(3,4),ad2(3,4),bd1(3,4),bd2(3,4)]);
d(4,3) = median([ad1(3,4),ad2(3,4),bd1(3,4),bd2(3,4)]);
d
error1(2) = sum(sum((dtrue-d).^2))/12/10^2;

d=zeros(4,4);
d(1,2) = median([ad3(1,2),bd3(1,2)]);
d(2,1) = median([ad3(1,2),bd3(1,2)]);
d(1,3) = median([ad3(1,3),bd3(1,3)]);
d(3,1) = median([ad3(1,3),bd3(1,3)]);
d(1,4) = median([ad3(1,4),bd3(1,4)]);
d(4,1) = median([ad3(1,4),bd3(1,4)]);
d(2,3) = median([ad3(2,3),bd3(2,3)]);
d(3,2) = median([ad3(2,3),bd3(2,3)]);
d(2,4) = median([ad3(2,4),bd3(2,4)]);
d(4,2) = median([ad3(2,4),bd3(2,4)]);
d(3,4) = median([ad3(3,4),bd3(3,4)]);
d(4,3) = median([ad3(3,4),bd3(3,4)]);
d
error2(2) = sum(sum((dtrue-d).^2))/12/10^2;

d=zeros(4,4);
d(1,2) = median([ad4(1,2),bd4(1,2)]);
d(2,1) = median([ad4(1,2),bd4(1,2)]);
d(1,3) = median([ad4(1,3),bd4(1,3)]);
d(3,1) = median([ad4(1,3),bd4(1,3)]);
d(1,4) = median([ad4(1,4),bd4(1,4)]);
d(4,1) = median([ad4(1,4),bd4(1,4)]);
d(2,3) = median([ad4(2,3),bd4(2,3)]);
d(3,2) = median([ad4(2,3),bd4(2,3)]);
d(2,4) = median([ad4(2,4),bd4(2,4)]);
d(4,2) = median([ad4(2,4),bd4(2,4)]);
d(3,4) = median([ad4(3,4),bd4(3,4)]);
d(4,3) = median([ad4(3,4),bd4(3,4)]);
d
error3(2) = sum(sum((dtrue-d).^2))/12/10^2;

% Look at first three paths (A,B,E) for linear case, (A,B,C) for general case
d = zeros(4,4);
d(1,2) = median([ad1(1,2),ad2(1,2),bd1(1,2),bd2(1,2),ed1(1,2),ed2(1,2)]);
d(2,1) = median([ad1(1,2),ad2(1,2),bd1(1,2),bd2(1,2),ed1(1,2),ed2(1,2)]);
d(1,3) = median([ad1(1,3),ad2(1,3),bd1(1,3),bd2(1,3),ed1(1,3),ed2(1,3)]);
d(3,1) = median([ad1(1,3),ad2(1,3),bd1(1,3),bd2(1,3),ed1(1,3),ed2(1,3)]);
d(1,4) = median([ad1(1,4),ad2(1,4),bd1(1,4),bd2(1,4),ed1(1,4),ed2(1,4)]);
d(4,1) = median([ad1(1,4),ad2(1,4),bd1(1,4),bd2(1,4),ed1(1,4),ed2(1,4)]);
d(2,3) = median([ad1(2,3),ad2(2,3),bd1(2,3),bd2(2,3),ed1(2,3),ed2(2,3)]);
d(3,2) = median([ad1(2,3),ad2(2,3),bd1(2,3),bd2(2,3),ed1(2,3),ed2(2,3)]);
d(2,4) = median([ad1(2,4),ad2(2,4),bd1(2,4),bd2(2,4),ed1(2,4),ed2(2,4)]);
d(4,2) = median([ad1(2,4),ad2(2,4),bd1(2,4),bd2(2,4),ed1(2,4),ed2(2,4)]);
d(3,4) = median([ad1(3,4),ad2(3,4),bd1(3,4),bd2(3,4),ed1(3,4),ed2(3,4)]);
d(4,3) = median([ad1(3,4),ad2(3,4),bd1(3,4),bd2(3,4),ed1(3,4),ed2(3,4)]);
d
error1(3) = sum(sum((dtrue-d).^2))/12/10^2;

d=zeros(4,4);
d(1,2) = median([ad3(1,2),bd3(1,2),cd3(1,2)]);
d(2,1) = median([ad3(1,2),bd3(1,2),cd3(1,2)]);
d(1,3) = median([ad3(1,3),bd3(1,3),cd3(1,3)]);
d(3,1) = median([ad3(1,3),bd3(1,3),cd3(1,3)]);
d(1,4) = median([ad3(1,4),bd3(1,4),cd3(1,4)]);
d(4,1) = median([ad3(1,4),bd3(1,4),cd3(1,4)]);
d(2,3) = median([ad3(2,3),bd3(2,3),cd3(2,3)]);
d(3,2) = median([ad3(2,3),bd3(2,3),cd3(2,3)]);
d(2,4) = median([ad3(2,4),bd3(2,4),cd3(2,4)]);
d(4,2) = median([ad3(2,4),bd3(2,4),cd3(2,4)]);
d(3,4) = median([ad3(3,4),bd3(3,4),cd3(3,4)]);
d(4,3) = median([ad3(3,4),bd3(3,4),cd3(3,4)]);
d
error2(3) = sum(sum((dtrue-d).^2))/12/10^2;

d=zeros(4,4);
d(1,2) = median([ad4(1,2),bd4(1,2),cd4(1,2)]);
d(2,1) = median([ad4(1,2),bd4(1,2),cd4(1,2)]);
d(1,3) = median([ad4(1,3),bd4(1,3),cd4(1,3)]);
d(3,1) = median([ad4(1,3),bd4(1,3),cd4(1,3)]);
d(1,4) = median([ad4(1,4),bd4(1,4),cd4(1,4)]);
d(4,1) = median([ad4(1,4),bd4(1,4),cd4(1,4)]);
d(2,3) = median([ad4(2,3),bd4(2,3),cd4(2,3)]);
d(3,2) = median([ad4(2,3),bd4(2,3),cd4(2,3)]);
d(2,4) = median([ad4(2,4),bd4(2,4),cd4(2,4)]);
d(4,2) = median([ad4(2,4),bd4(2,4),cd4(2,4)]);
d(3,4) = median([ad4(3,4),bd4(3,4),cd4(3,4)]);
d(4,3) = median([ad4(3,4),bd4(3,4),cd4(3,4)]);
d
error3(3) = sum(sum((dtrue-d).^2))/12/10^2;

% Look at all 4 paths
d = zeros(4,4);
d(1,2) = median([ad1(1,2),ad2(1,2),bd1(1,2),bd2(1,2),ed1(1,2),ed2(1,2),fd1(1,2),fd2(1,2)]);
d(2,1) = median([ad1(1,2),ad2(1,2),bd1(1,2),bd2(1,2),ed1(1,2),ed2(1,2),fd1(1,2),fd2(1,2)]);
d(1,3) = median([ad1(1,3),ad2(1,3),bd1(1,3),bd2(1,3),ed1(1,3),ed2(1,3),fd1(1,3),fd2(1,3)]);
d(3,1) = median([ad1(1,3),ad2(1,3),bd1(1,3),bd2(1,3),ed1(1,3),ed2(1,3),fd1(1,3),fd2(1,3)]);
d(1,4) = median([ad1(1,4),ad2(1,4),bd1(1,4),bd2(1,4),ed1(1,4),ed2(1,4),fd1(1,4),fd2(1,4)]);
d(4,1) = median([ad1(1,4),ad2(1,4),bd1(1,4),bd2(1,4),ed1(1,4),ed2(1,4),fd1(1,4),fd2(1,4)]);
d(2,3) = median([ad1(2,3),ad2(2,3),bd1(2,3),bd2(2,3),ed1(2,3),ed2(2,3),fd1(2,3),fd2(2,3)]);
d(3,2) = median([ad1(2,3),ad2(2,3),bd1(2,3),bd2(2,3),ed1(2,3),ed2(2,3),fd1(2,3),fd2(2,3)]);
d(2,4) = median([ad1(2,4),ad2(2,4),bd1(2,4),bd2(2,4),ed1(2,4),ed2(2,4),fd1(2,4),fd2(2,4)]);
d(4,2) = median([ad1(2,4),ad2(2,4),bd1(2,4),bd2(2,4),ed1(2,4),ed2(2,4),fd1(2,4),fd2(2,4)]);
d(3,4) = median([ad1(3,4),ad2(3,4),bd1(3,4),bd2(3,4),ed1(3,4),ed2(3,4),fd1(3,4),fd2(3,4)]);
d(4,3) = median([ad1(3,4),ad2(3,4),bd1(3,4),bd2(3,4),ed1(3,4),ed2(3,4),fd1(3,4),fd2(3,4)]);
d
error1(4) = sum(sum((dtrue-d).^2))/12/10^2;

d=zeros(4,4);
d(1,2) = median([ad3(1,2),bd3(1,2),cd3(1,2),dd3(1,2)]);
d(2,1) = median([ad3(1,2),bd3(1,2),cd3(1,2),dd3(1,2)]);
d(1,3) = median([ad3(1,3),bd3(1,3),cd3(1,3),dd3(1,3)]);
d(3,1) = median([ad3(1,3),bd3(1,3),cd3(1,3),dd3(1,3)]);
d(1,4) = median([ad3(1,4),bd3(1,4),cd3(1,4),dd3(1,4)]);
d(4,1) = median([ad3(1,4),bd3(1,4),cd3(1,4),dd3(1,4)]);
d(2,3) = median([ad3(2,3),bd3(2,3),cd3(2,3),dd3(2,3)]);
d(3,2) = median([ad3(2,3),bd3(2,3),cd3(2,3),dd3(2,3)]);
d(2,4) = median([ad3(2,4),bd3(2,4),cd3(2,4),dd3(2,4)]);
d(4,2) = median([ad3(2,4),bd3(2,4),cd3(2,4),dd3(2,4)]);
d(3,4) = median([ad3(3,4),bd3(3,4),cd3(3,4),dd3(3,4)]);
d(4,3) = median([ad3(3,4),bd3(3,4),cd3(3,4),dd3(3,4)]);
d
error2(4) = sum(sum((dtrue-d).^2))/12/10^2;

d=zeros(4,4);
d(1,2) = median([ad4(1,2),bd4(1,2),cd4(1,2),dd4(1,2)]);
d(2,1) = median([ad4(1,2),bd4(1,2),cd4(1,2),dd4(1,2)]);
d(1,3) = median([ad4(1,3),bd4(1,3),cd4(1,3),dd4(1,3)]);
d(3,1) = median([ad4(1,3),bd4(1,3),cd4(1,3),dd4(1,3)]);
d(1,4) = median([ad4(1,4),bd4(1,4),cd4(1,4),dd4(1,4)]);
d(4,1) = median([ad4(1,4),bd4(1,4),cd4(1,4),dd4(1,4)]);
d(2,3) = median([ad4(2,3),bd4(2,3),cd4(2,3),dd4(2,3)]);
d(3,2) = median([ad4(2,3),bd4(2,3),cd4(2,3),dd4(2,3)]);
d(2,4) = median([ad4(2,4),bd4(2,4),cd4(2,4),dd4(2,4)]);
d(4,2) = median([ad4(2,4),bd4(2,4),cd4(2,4),dd4(2,4)]);
d(3,4) = median([ad4(3,4),bd4(3,4),cd4(3,4),dd4(3,4)]);
d(4,3) = median([ad4(3,4),bd4(3,4),cd4(3,4),dd4(3,4)]);
d
error3(4) = sum(sum((dtrue-d).^2))/12/10^2;


if plotFig == 1
    figure(fignum)
    x = 1:1:4;
    hold on;
    plot(x,error1,'k-','LineWidth',2);
    plot(x,error2,'k:','LineWidth',2);
    plot(x,error3,'k--','LineWidth',2);
    title('Error over multiple Trajectories','fontWeight','bold');
    xlabel('Number of Trajectories included');
    ylabel('Mean Squared Error (cm^2)','fontWeight','bold');
    legend('CPA Error over Linear Paths (A,B,E,F)','Sum Error over Paths (A,B,C,D)','Diff Error over Paths (A,B,C,D');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;
    print('-dpng', plotName);
    print('-depsc', plotName);

end
