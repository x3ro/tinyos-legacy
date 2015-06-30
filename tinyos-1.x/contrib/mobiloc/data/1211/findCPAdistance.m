function [din, dout] = findCPAdistance(x1,x2,x3,x4,plotFigures,figurenum)
% [din, dout] = findCPAdistance(x1,x2,x3,x4,plotFigures,figurenum)
%
% Output the distance calculations for the closest point of approach
% method (both case1 and case2).  Do this for each pair of nodes.
% If plotFigures == 1, will plot the node ranges

% Nodes 1 and 2
[r11 index1] = min(x1(:,2));
[r22 index2] = min(x2(:,2));
x = x1(:,1);
i = find(x == x2(index2,1));
while isempty(i)
    if index2 + 5 >= length(x2)
        index2 = index2 - 1;
    elseif index2 - 5 <= 0
        index2 = index2 + 1;
    else
        index2 = index2 - 1;
    end
    i = find(x == x2(index2,1));
end
r12 = x1(i,2);
x = x2(:,1);
i = find(x == x1(index1,1));
while isempty(i)
    if index1 + 5 >= length(x1)
        index1 = index1 - 1;
    elseif index2 - 5 <= 0
        index1 = index1 + 1;
    else
        index1 = index1 - 1;
    end
    i = find(x == x1(index1,1));
end
r21 = x2(i,2);

din(1,2) = sqrt(r11^2 + r21^2 + 2*r11*r22);
din(2,1) = sqrt(r11^2 + r21^2 + 2*r11*r22);
dout(1,2) = sqrt(r11^2 + r21^2 - 2*r11*r22);
dout(2,1) = sqrt(r11^2 + r21^2 - 2*r11*r22);

% Nodes 1 and 3
[r11 index1] = min(x1(:,2));
[r22 index2] = min(x3(:,2));
x = x1(:,1);
i = find(x == x3(index2,1));
while isempty(i)
    if index2 + 5 >= length(x3)
        index2 = index2 - 1;
    elseif index2 - 5 <= 0
        index2 = index2 + 1;
    else
        index2 = index2 - 1;
    end
    i = find(x == x3(index2,1));
end
r12 = x1(i,2);
x = x3(:,1);
i = find(x == x1(index1,1));
while isempty(i)
    if index1 + 5 >= length(x1)
        index1 = index1 - 1;
    elseif index1 - 5 <= 0
        index1 = index1 + 1;
    else
        index1 = index1 - 1;
    end
    i = find(x == x1(index1,1));
end
r21 = x3(i,2);

din(1,3) = sqrt(r11^2 + r21^2 + 2*r11*r22);
din(3,1) = sqrt(r11^2 + r21^2 + 2*r11*r22);
dout(1,3) = sqrt(r11^2 + r21^2 - 2*r11*r22);
dout(3,1) = sqrt(r11^2 + r21^2 - 2*r11*r22);

% Nodes 1 and 4
[r11 index1] = min(x1(:,2));
[r22 index2] = min(x4(:,2));
x = x1(:,1);
i = find(x == x4(index2,1));
while isempty(i)
    if index2 + 5 >= length(x4)
        index2 = index2 - 1;
    elseif index2 - 5 <= 0
        index2 = index2 + 1;
    else
        index2 = index2 - 1;
    end
    i = find(x == x4(index2,1));
end
r12 = x1(i,2);
x = x4(:,1);
i = find(x == x1(index1,1));
while isempty(i)
    if index1 + 5 >= length(x1)
        index1 = index1 - 1;
    elseif index1 - 5 <= 0
        index1 = index1 + 1;
    else
        index1 = index1 - 1;
    end
    i = find(x == x1(index1,1));
end
r21 = x4(i,2);

din(1,4) = sqrt(r11^2 + r21^2 + 2*r11*r22);
din(4,1) = sqrt(r11^2 + r21^2 + 2*r11*r22);
dout(1,4) = sqrt(r11^2 + r21^2 - 2*r11*r22);
dout(4,1) = sqrt(r11^2 + r21^2 - 2*r11*r22);

% Nodes 2 and 3
[r11 index1] = min(x2(:,2));
[r22 index2] = min(x3(:,2));
x = x2(:,1);
i = find(x == x3(index2,1));
while isempty(i)
    if index2 + 5 >= length(x3)
        index2 = index2 - 1;
    elseif index2 - 5 <= 0
        index2 = index2 + 1;
    else
        index2 = index2 - 1;
    end
    i = find(x == x3(index2,1));
end
r12 = x2(i,2);
x = x3(:,1);
i = find(x == x2(index1,1));
while isempty(i)
    if index1 + 5 >= length(x2)
        index1 = index1 - 1;
    elseif index1 - 5 <= 0
        index1 = index1 + 1;
    else
        index1 = index1 - 1;
    end
    i = find(x == x2(index1,1));
end
r21 = x3(i,2);

din(2,3) = sqrt(r11^2 + r21^2 + 2*r11*r22);
din(3,2) = sqrt(r11^2 + r21^2 + 2*r11*r22);
dout(2,3) = sqrt(r11^2 + r21^2 - 2*r11*r22);
dout(3,2) = sqrt(r11^2 + r21^2 - 2*r11*r22);

% Nodes 2 and 4
[r11 index1] = min(x2(:,2));
[r22 index2] = min(x4(:,2));
x = x2(:,1);
i = find(x == x4(index2,1));
while isempty(i)
    if index2 + 5 >= length(x4)
        index2 = index2 - 1;
    elseif index2 - 5 <= 0
        index2 = index2 + 1;
    else
        index2 = index2 - 1;
    end
    i = find(x == x4(index2,1));
end
r12 = x2(i,2);
x = x4(:,1);
i = find(x == x2(index1,1));
while isempty(i)
    if index1 + 5 >= length(x2)
        index1 = index1 - 1;
    elseif index1 - 5 <= 0
        index1 = index1 + 1;
    else
        index1 = index1 - 1;
    end
    i = find(x == x2(index1,1));
end
r21 = x4(i,2);

din(2,4) = sqrt(r11^2 + r21^2 + 2*r11*r22);
din(4,2) = sqrt(r11^2 + r21^2 + 2*r11*r22);
dout(2,4) = sqrt(r11^2 + r21^2 - 2*r11*r22);
dout(4,2) = sqrt(r11^2 + r21^2 - 2*r11*r22);

% Nodes 3 and 4
[r11 index1] = min(x3(:,2));
[r22 index2] = min(x4(:,2));
x = x3(:,1);
i = find(x == x4(index2,1));
while isempty(i)
    if index2 + 5 >= length(x4)
        index2 = index2 - 1;
    elseif index2 - 5 <= 0
        index2 = index2 + 1;
    else
        index2 = index2 - 1;
    end
    i = find(x == x4(index2,1));
end
r12 = x3(i,2);
x = x4(:,1);
i = find(x == x3(index1,1));
while isempty(i)
    if index1 + 5 >= length(x3)
        index1 = index1 - 1;
    elseif index1 - 5 <= 0
        index1 = index1 + 1;
    else
        index1 = index1 - 1;
    end
    i = find(x == x3(index1,1));
end
r21 = x4(i,2);

din(3,4) = sqrt(r11^2 + r21^2 + 2*r11*r22);
din(4,3) = sqrt(r11^2 + r21^2 + 2*r11*r22);
dout(3,4) = sqrt(r11^2 + r21^2 - 2*r11*r22);
dout(4,3) = sqrt(r11^2 + r21^2 - 2*r11*r22);

if plotFigures == 1
    figure(figurenum)

    subplot(2,3,1),
    hold on;
    plot(x1(:,1),x1(:,2),'b','LineWidth',2);
    plot(x2(:,1),x2(:,2),'r','LineWidth',2);
    title('Nodes 1 and 2','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,2),
    hold on;
    plot(x1(:,1),x1(:,2),'b','LineWidth',2);
    plot(x3(:,1),x3(:,2),'r','LineWidth',2);
    title('Nodes 1 and 3','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,3),
    hold on;
    plot(x1(:,1),x1(:,2),'b','LineWidth',2);
    plot(x4(:,1),x4(:,2),'r','LineWidth',2);
    title('Nodes 1 and 4','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,4),
    hold on;
    plot(x2(:,1),x2(:,2),'b','LineWidth',2);
    plot(x3(:,1),x3(:,2),'r','LineWidth',2);
    title('Nodes 2 and 3','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,5),
    hold on;
    plot(x2(:,1),x2(:,2),'b','LineWidth',2);
    plot(x4(:,1),x4(:,2),'r','LineWidth',2);
    title('Nodes 2 and 4','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;

    subplot(2,3,6),
    hold on;
    plot(x3(:,1),x3(:,2),'b','LineWidth',2);
    plot(x4(:,1),x4(:,2),'r','LineWidth',2);
    title('Nodes 3 and 4','fontWeight','bold');
    xlabel('Sample Number');
    ylabel('Distance (mm)','fontWeight','bold');
    axis square;
    set(gca,'LineWidth',2,'fontWeight','bold');
    hold off;
end

