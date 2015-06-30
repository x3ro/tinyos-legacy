function update_topology(id, parent)
global rsc

% change parent for base station pointing to itself
basestation_index = find(rsc.basestationID == id);
parent(basestation_index) = rsc.basestationID;

% check to see if there is any change before we waste time drawing it
history_parent = rsc.parent;
history_id = rsc.nodesID;

%% find the index of id in history_id
[blah, known_index] = intersect(history_id, id);
[unique_id, unique_id_index] = unique(id);
% since there can be more than one same node_id in id
% we need to find the latest one. this will give the value of the latest parent
new_known_parent = parent(unique_id_index);
% extract the old parent from history_parent
old_known_parent = history_parent(known_index);
% compare them
same_index = (old_known_parent == new_known_parent);
% if they are not equal there will be 0s in same_index
% so length is more than 0
if (length(find(same_index == 0)) == 0)
    % that means there is no change
    return;
end
% save down the new information
history_parent(known_index) = new_known_parent;
rsc.parent = history_parent;
% draw the topology
draw_topology(history_id, history_parent, rsc.coor, rsc.basestationID);
