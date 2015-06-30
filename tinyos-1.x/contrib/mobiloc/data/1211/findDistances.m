function [ad1,ad2,ad3,ad4,bd1,bd2,bd3,bd4,cd1,cd2,cd3,cd4,dd1,dd2,dd3,dd4,ed1,ed2,ed3,ed4,fd1,fd2,fd3,fd4] = findDistances(plotFigures,ax1,ax2,ax3,ax4,bx1,bx2,bx3,bx4,cx1,cx2,cx3,cx4,dx1,dx2,dx3,dx4,ex1,ex2,ex3,ex4,fx1,fx2,fx3,fx4)
% [ad1,ad2,ad3,ad4,bd1,bd2,bd3,bd4,cd1,cd2,cd3,cd4,dd1,dd2,dd3,dd4] = findDistances(plotFigures,ax1,ax2,ax3,ax4,bx1,bx2,bx3,bx4,cx1,cx2,cx3,cx4,dx1,dx2,dx3,dx4)
%
% This function takes in the data and finds the four distances for each set of data
% (din, dout) (dplus, dminus).
% d1 = din
% d2 = dout
% d3 = dplus
% d4 = dminus
% Ideally, I would like to take this range data and find the positions from it.

[ad1, ad2] = findCPAdistance(ax1,ax2,ax3,ax4,0,1);
[bd1, bd2] = findCPAdistance(bx1,bx2,bx3,bx4,0,2);
[cd1, cd2] = findCPAdistance(cx1,cx2,cx3,cx4,0,3);
[dd1, dd2] = findCPAdistance(dx1,dx2,dx3,dx4,0,4);
[ed1, ed2] = findCPAdistance(ex1,ex2,ex3,ex4,0,5);
[fd1, fd2] = findCPAdistance(fx1,fx2,fx3,fx4,0,6);

[ad3, ad4] = plotMinSumMaxDiff(ax1,ax2,ax3,ax4,plotFigures,1,'r','b','SumDifferencePlotA');
[bd3, bd4] = plotMinSumMaxDiff(bx1,bx2,bx3,bx4,plotFigures,2,'r','b','SumDifferencePlotB');
[cd3, cd4] = plotMinSumMaxDiff(cx1,cx2,cx3,cx4,plotFigures,3,'r','b','SumDifferencePlotC');
[dd3, dd4] = plotMinSumMaxDiff(dx1,dx2,dx3,dx4,plotFigures,4,'r','b','SumDifferencePlotD');
[ed3, ed4] = plotMinSumMaxDiff(ex1,ex2,ex3,ex4,plotFigures,5,'r','b','SumDifferencePlotE');
[fd3, fd4] = plotMinSumMaxDiff(fx1,fx2,fx3,fx4,plotFigures,6,'r','b','SumDifferencePlotF');

