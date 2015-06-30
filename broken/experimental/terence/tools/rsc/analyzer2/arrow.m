function output = arrow(varargin)
output = feval(varargin{:});

function angle = degree2radian(angle)
angle = angle * 2 * pi / 360;

function angle = radian2degree(radian)
angle = radian * 360 / (2 * pi);

% row vector convention
% x = [1 0 0 1]; x * rotateMatrix(30)
function matrix = rotateMatrix(angle)
angle = degree2radian(angle);
matrix(1, 1) = cos(angle);
matrix(1, 2) = sin(angle);
matrix(2, 1) = -sin(angle);
matrix(2, 2) = cos(angle);
matrix(3, 3) = 1;
matrix(4, 4) = 1;

function matrix = scale(x, y)
matrix(1, 1) = x;
matrix(2, 2) = y;
matrix(3, 3) = 1;
matrix(4, 4) = 1;

function matrix = translate(x, y)
matrix(1, 1) = 1;
matrix(2, 2) = 1;
matrix(3, 3) = 1;
matrix(4, 4) = 1;
matrix(4, 1) = x;
matrix(4, 2) = y;

function [rhead, rbottom, rleft, rright] = multiplyAll(head, bottom, left, right, matrix)
rhead = head * matrix;
rbottom = bottom * matrix;
rleft = left * matrix;
rright = right * matrix;

function angle = myarctan(diffx, diffy)
if (diffx == 0 & diffy > 0)
    angle = 90;
elseif (diffx == 0 & diffy < 0)
    angle = -90;
else
    angle = atan(diffy / diffx);
    angle = radian2degree(angle);
end
if (diffx < 0)
    angle = angle + 180;
end

function handles = quiver(sx, sy, dx, dy, spear_length)
diffx = dx - sx;
diffy = dy - sy;
length = sqrt(diffx ^ 2 + diffy ^ 2);
angle = myarctan(diffx, diffy);
spear_angle = 30;
[head, bottom, left, right] = defineArrow(length, spear_length, spear_angle, [sx, sy], angle);
handles = drawArrow(head, bottom, left, right);
% centerView;

function [head, bottom, left, right] = defineArrow(length, spear_length, spear_angle, start_coor, angle)
% an arrow pointing up to origin
left = [spear_length 0 0 1];
right = left;
left = left * rotateMatrix(270 - spear_angle);
right = right * rotateMatrix(270 + spear_angle);
bottom = [0 -length 0 1];
head = [0 0 0 1];

% move the bottom to origin
[head, bottom, left, right] = multiplyAll(head, bottom, left, right, translate(0, length));

% rotate facing / pointing to the east
[head, bottom, left, right] = multiplyAll(head, bottom, left, right, rotateMatrix(-90));

% rotate by angle
[head, bottom, left, right] = multiplyAll(head, bottom, left, right, rotateMatrix(angle));

% translate to start coor
[head, bottom, left, right] = multiplyAll(head, bottom, left, right, translate(start_coor(1), start_coor(2)));

%% given four points, draw the arrow
function handles = drawArrow(head, bottom, left, right)
handles(1) = line([head(1) bottom(1)], [head(2) bottom(2)]);
hold on;
handles(2) = line([head(1) left(1)], [head(2) left(2)]);
hold on;
handles(3) = line([head(1) right(1)], [head(2) right(2)]);
hold off;

function output = centerView

children_handles = get(gca, 'Children');
maxX = -1e9;
minX = 1e9;
maxY = -1e9;
minY = 1e9;
for i = 1:length(children_handles)
    if (isfield(children_handles(i), 'XData') == 0), continue;, end
    maxX = max([maxX get(children_handles(i), 'XData')]);
    minX = min([minX get(children_handles(i), 'XData')]);
    maxY = max([maxY get(children_handles(i), 'YData')]);
    minY = min([minY get(children_handles(i), 'YData')]);
end
center = [(maxX + minX) / 2, (maxY + minY) / 2];
max_range = max([abs(maxX - center(1)), ...
    abs(minX - center(1)), ...
    abs(maxY - center(2)), ...
    abs(minY - center(2))]);
try
axis([center(1) - max_range, center(1) + max_range, center(2) - max_range, center(2) + max_range]);
catch
end
output = -1;



