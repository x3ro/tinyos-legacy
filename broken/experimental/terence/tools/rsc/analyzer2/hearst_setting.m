function [nodesID, coor, basestationID] = hearst_setting
nodesID = 1:50;
coor = [];
for i = nodesID
    x = mod((i - 1), 10) * 8;
    y = fix((i - 1) / 10) * 8;
    coor = [coor; x, y];
end
% swap 21 and 1
temp = coor(21, :);
coor(21, :) = coor(1, :);
coor(1, :) = temp;
basestationID = 1;

