function queryNodeParent
global VIS;

VIS.crumb.route_counter = VIS.crumb.route_counter + 1;
route_counter = VIS.crumb.route_counter;
if (route_counter > 5)
    VIS.crumb.route_counter = 0;    
    invalid_parent_index = find([VIS.node.parent] == -1);
  % kill the landmark
    landmark_index = getNodeIdx(VIS.landmark);
    invalid_parent_index = [invalid_parent_index(1:(landmark_index - 1)), ...
        invalid_parent_index((landmark_index + 1):length(invalid_parent_index))];
    
    if (~isempty(invalid_parent_index))
        query_index = invalid_parent_index(floor(rand * length(invalid_parent_index)) + 1);    
        query_node_id = VIS.nodeIdx(query_index);
        cmd = ['peg ' num2str(query_node_id) ' ststatus'];
        eval(cmd);
    else
        1;
    end
end


