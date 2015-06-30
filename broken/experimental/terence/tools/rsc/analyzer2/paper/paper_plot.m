function output = paper_plot(varargin)
output = feval(varargin{:});

function output = init
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
tablename = '';
cla;
core('init', nodesID, coor, tablename, basestationID);
new_children;
output = -1;

function output = set_property(handles, type, field, value)
output = -1;
for i = 1:length(handles)
    if strcmpi(type, get(handles(i), 'type')) == 0
        continue;
    end
    try
        set(handles(i), field, value);
    catch
    end
end

function diff = new_children
global old_children
current_children = get(gca, 'Children');
diff = setdiff(current_children, old_children);
old_children = current_children;


