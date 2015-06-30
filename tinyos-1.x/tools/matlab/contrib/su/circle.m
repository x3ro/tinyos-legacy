function h = circle(x,y,r,c)
% circle(x,y,r), draw a circle with center (x,y) and radius r. 
% c is the color, it can be 'r','b','g', 'b' etc. If it is not % given, it will be the default.

if nargin < 4, c = 'k'; end

phi = 0:0.01:2*pi;
nx = x+r*cos(phi);
ny = y+r*sin(phi);

h = plot(nx,ny,c);
axis equal

