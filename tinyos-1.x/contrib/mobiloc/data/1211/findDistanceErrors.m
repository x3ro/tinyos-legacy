function  error = findDistanceErrors(plotBar,fignum,plotName,ad1,ad2,ad3,ad4,bd1,bd2,bd3,bd4,cd1,cd2,cd3,cd4,dd1,dd2,dd3,dd4)
% error = findDistanceErrors(plotBar,ad1,ad2,ad3,ad4,bd1,bd2,bd3,bd4,cd1,cd2,cd3,cd4,dd1,dd2,dd3,dd4)
%
% 

dtrue = [0 700 900 1140; 700 0 1140 900; 900 1140 0 700; 1140 900 700 0];

error(1,1) = sum(sum((dtrue-ad1).^2))/12/10^2;
error(1,2) = sum(sum((dtrue-ad2).^2))/12/10^2;
error(1,3) = sum(sum((dtrue-ad3).^2))/12/10^2;
error(1,4) = sum(sum((dtrue-ad4).^2))/12/10^2;

error(2,1) = sum(sum((dtrue-bd1).^2))/12/10^2;
error(2,2) = sum(sum((dtrue-bd2).^2))/12/10^2;
error(2,3) = sum(sum((dtrue-bd3).^2))/12/10^2;
error(2,4) = sum(sum((dtrue-bd4).^2))/12/10^2;

error(3,1) = sum(sum((dtrue-cd1).^2))/12/10^2;
error(3,2) = sum(sum((dtrue-cd2).^2))/12/10^2;
error(3,3) = sum(sum((dtrue-cd3).^2))/12/10^2;
error(3,4) = sum(sum((dtrue-cd4).^2))/12/10^2;

error(4,1) = sum(sum((dtrue-dd1).^2))/12/10^2;
error(4,2) = sum(sum((dtrue-dd2).^2))/12/10^2;
error(4,3) = sum(sum((dtrue-dd3).^2))/12/10^2;
error(4,4) = sum(sum((dtrue-dd4).^2))/12/10^2;

if plotBar == 1
    figure(fignum)
    width = 0.8;
    nicecolor = [0 0 1; 0 1 0; 1 0 0; 0 0 0];
    colormap(nicecolor);
    bar(error,width,'grouped');
    set(gca,'XTick',[1:16]);
    xticklabels = ['A';'B';'C';'D'];
    set(gca,'XTickLabels',xticklabels,'fontWeight','bold')
    %set(gca,'XMinorTick','on');
    legend('CPA, Case 1','CPA, Case 2','Sum','Difference',2);
    
    title('Mean Squared Error','fontWeight','bold');
    xlabel('Path and Distance Estimation Method');
    ylabel('Mean Squared Error (cm^2)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    print('-dpng', plotName);
    print('-depsc', plotName);

end
