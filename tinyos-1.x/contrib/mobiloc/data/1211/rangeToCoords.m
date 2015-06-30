function rangeToCoords(r,color1,color2,fignum,plotname)
% rangeToCoords(r,color1,color2,fignum,plotname)
%
% Takes in a range matrix r of the following structure
% [0    r12     r13     r14;
%  r21  0       r23     r24;
%  r31  r32     0       r34;
%  r41  r42     r43     0];
%
% In return, it will plot the coordinates based on a local coordinate
% system with node 1 at (0,0) and node 2 at (r12,0).

motePositions = [0 0; 700 0; 0 900; 700 900];
r12 = r(1,2);
r13 = r(1,3);
r14 = r(1,4);
r23 = r(2,3);
r24 = r(2,4);
% Never use r34!

% Find x3
x3 = (-1/(2*r12))*(r23^2-r13^2-r12^2);
phi = acos(x3/r13);
y3 = r13*sin(phi);

% Find x4
x4 = (-1/(2*r12))*(r24^2-r14^2-r12^2);
theta = acos(x4/r14);
y4 = r14*sin(theta);

guessPositions = [0 0; r12 0; x3 y3; x4 y4];

hold on;
% plot actual positions
scatter(motePositions(:,1),motePositions(:,2),50,color1,'filled');
% plot guess positions
scatter(guessPositions(:,1),guessPositions(:,2),50,color2,'filled');
title('Real v. Guess Coordinates','fontWeight','bold');
xlabel('x (mm)');
ylabel('y (mm)','fontWeight','bold');
axis square;
set(gca,'LineWidth',2,'fontWeight','bold');
hold off;

%print('-dpng', plotname);
%print('-depsc', plotname);