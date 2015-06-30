function [sum, diff] = plotMinSumMaxDiff(x1,x2,x3,x4,plotFigures,figurenum,sumcolor,diffcolor,filename)
% [sum, diff] = plotMinSumMaxDiff(x1,x2,x3,x4,plotFigures,figurenum,sumcolor,diffcolor,fileName)
%
% Plots the sum of each pairwise signal and the diff of each pairwise signal and save the resulting
% plot as filename
% if plotFigures == 1, plot sums and differences

sum12 = x1(1:min(length(x1),length(x2)),2) + x2(1:min(length(x1),length(x2)),2);
diff12 = abs(x1(1:min(length(x1),length(x2)),2) - x2(1:min(length(x1),length(x2)),2));
sum(1,2) = min(sum12);
sum(2,1) = min(sum12);
diff(1,2) = max(diff12);
diff(2,1) = max(diff12);

sum13 = x1(1:min(length(x1),length(x3)),2) + x3(1:min(length(x1),length(x3)),2);
diff13 = abs(x1(1:min(length(x1),length(x3)),2) - x3(1:min(length(x1),length(x3)),2));
sum(1,3) = min(sum13);
sum(3,1) = min(sum13);
diff(1,3) = max(diff13);
diff(3,1) = max(diff13);

sum14 = x1(1:min(length(x1),length(x4)),2) + x4(1:min(length(x1),length(x4)),2);
diff14 = abs(x1(1:min(length(x1),length(x4)),2) - x4(1:min(length(x1),length(x4)),2));
sum(1,4) = min(sum14);
sum(4,1) = min(sum14);
diff(1,4) = max(diff14);
diff(4,1) = max(diff14);

sum23 = x2(1:min(length(x2),length(x3)),2) + x3(1:min(length(x2),length(x3)),2);
diff23 = abs(x2(1:min(length(x2),length(x3)),2) - x3(1:min(length(x2),length(x3)),2));
sum(2,3) = min(sum23);
sum(3,2) = min(sum23);
diff(2,3) = max(diff23);
diff(3,2) = max(diff23);

sum24 = x2(1:min(length(x2),length(x4)),2) + x4(1:min(length(x2),length(x4)),2);
diff24 = abs(x2(1:min(length(x2),length(x4)),2) - x4(1:min(length(x2),length(x4)),2));
sum(2,4) = min(sum24);
sum(4,2) = min(sum24);
diff(2,4) = max(diff24);
diff(4,2) = max(diff24);

sum34 = x3(1:min(length(x3),length(x4)),2) + x4(1:min(length(x3),length(x4)),2);
diff34 = abs(x3(1:min(length(x3),length(x4)),2) - x4(1:min(length(x3),length(x4)),2));
sum(3,4) = min(sum34);
sum(4,3) = min(sum34);
diff(3,4) = max(diff34);
diff(4,3) = max(diff34);

if plotFigures == 1
    figure(figurenum)

    subplot(2,3,1),
    hold on;
    plot(1:length(sum12),sum12,sumcolor,'LineWidth',2);
    plot(1:length(diff12),diff12,diffcolor,'LineWidth',2);
    plot(1:max(length(sum12),length(diff12)),700,'k-','LineWidth',2);
    title('1+2, |1-2|','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    axis([1,min(length(x1),length(x2)),min(diff12),max(sum12)]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,2),
    hold on;
    plot(1:length(sum13),sum13,sumcolor,'LineWidth',2);
    plot(1:length(diff13),diff13,diffcolor,'LineWidth',2);
    title('1+3, |1-3|','fontWeight','bold');
    plot(1:max(length(sum13),length(diff13)),900,'k-','LineWidth',2);
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    axis([1,min(length(x1),length(x3)),min(diff13),max(sum13)]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,3),
    hold on;
    plot(1:length(sum14),sum14,sumcolor,'LineWidth',2);
    plot(1:length(diff14),diff14,diffcolor,'LineWidth',2);
    plot(1:max(length(sum14),length(diff14)),1140,'k-','LineWidth',2);
    title('1+4, |1-4|','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    axis([1,min(length(x1),length(x4)),min(diff14),max(sum14)]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,4),
    hold on;
    plot(1:length(sum23),sum23,sumcolor,'LineWidth',2);
    plot(1:length(diff23),diff23,diffcolor,'LineWidth',2);
    plot(1:max(length(sum23),length(diff23)),1140,'k-','LineWidth',2);
    title('2+3, |2-3|','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    axis([1,min(length(x2),length(x3)),min(diff23),max(sum23)]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,5),
    hold on;
    plot(1:length(sum24),sum24,sumcolor,'LineWidth',2);
    plot(1:length(diff24),diff24,diffcolor,'LineWidth',2);
    plot(1:max(length(sum24),length(diff24)),900,'k-','LineWidth',2);
    title('2+4, |2-4|','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    axis([1,min(length(x2),length(x4)),min(diff24),max(sum24)]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,6),
    hold on;
    plot(1:length(sum34),sum34,sumcolor,'LineWidth',2);
    plot(1:length(diff34),diff34,diffcolor,'LineWidth',2);
    plot(1:max(length(sum34),length(diff34)),700,'k-','LineWidth',2);
    title('3+4, |3-4|','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    axis([1,min(length(x3),length(x4)),min(diff34),max(sum34)]);
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    print('-dpng', filename);
    print('-depsc', filename);
end
