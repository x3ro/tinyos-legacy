
function draw_topology(id, parent, coor, basestationID)
% parent = 0:49; parent(1) = 1;
% id = 1:50;
clf;
hold on
set(gca, 'Color', [0 0 0]);
for i = 1:length(id);
    node_id = id(i);
    parent_id = parent(i);
    
    if (node_id == parent_id)
        continue;
    end
    if (basestationID == node_id)
        continue;
    end
    parent_index = find(parent_id == id);
    
    node_x = coor(i, 1);
    node_y = coor(i, 2);
    
    parent_x = coor(parent_index, 1);
    parent_y = coor(parent_index, 2);
    
    color = [rand rand rand];
    hold on
    
    node_handles = plot(node_x, node_y, '-g.');
    set(node_handles, 'MarkerSize', 30);
    set(node_handles, 'Color', color);
    hold on

    arrow_handles =  arrow('quiver', node_x, node_y, parent_x, parent_y, 2);
    set(arrow_handles, 'LineWidth', 2.5);
    set(arrow_handles, 'Color', color);
    hold on
    
end
hold off

