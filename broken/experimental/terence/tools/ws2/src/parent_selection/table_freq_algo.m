function result = table_freq_algo(varargin)
result = feval(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This simply check to see if the nodeID is in the table.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = isInTable(id, table)
bool = 0;
if isempty(table.nodeID)
    result = bool;
    return;
end

tmp = find(table.nodeID == id);
if ~isempty(tmp)
    bool = 1;
end
result = bool;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This simply inserts the node signaled by the packet.
%    in_table - is the queue
%    table_size - queue size
%    token - is the node
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = insert(id, receive_packet, protocolName);
global protocol_params all_mote;
table = protocol_params.neighbor_list(id);

% Retrive downsampling rate
% In TinyOS, this is tableSIZE/number of neighbor.
downSampleRate = protocol_params.neighbor_list(id).downSamplingRate;
table_size = protocol_params.neighbor_list(id).size;
result = protocol_params.neighbor_list(id);

% Check to see if the node is in the table already or not.
if isInTable(receive_packet.source,protocol_params.neighbor_list(id)) == 0
    % If it is not in the table, we have to throw a coin to see if we want to insert it
    % Perform downsampling
    if rand >= downSampleRate
        return ;     
    end

    % Now, we want to insert it only if it is not my sibling
    if receive_packet.type == protocol_params.route_packet_type
        if abs(all_mote.cost(id) - receive_packet.cost) < 1
            return;
        end
    end
else    
    % It is in the table already, make sure it doesn't become a sbiling
    % if it does, drop it by setting its freq count to 0
    if receive_packet.type == protocol_params.route_packet_type
        if abs(all_mote.cost(id) - receive_packet.cost) < 1
            % delete this sibling
            [val, index]=find(protocol_params.neighbor_list(id).nodeID==receive_packet.source);
            protocol_params.neighbor_list(id).freq(index) = 0;
            return;
        end
    end
end

% Now, we are sure we want to insert the node into the table if it is new
% or modify its freq count if it is in the tabl already.

% Insert the node if the table is empty
if isempty(protocol_params.neighbor_list(id).nodeID)
    feval(protocolName, 'new_neighbor_entry', 1, id, receive_packet);
    protocol_params.neighbor_list(id).freq(1) = 1;
    result = protocol_params.neighbor_list(id);
    return ;
end

% see if the node is in the table or not
[val, index]=find(protocol_params.neighbor_list(id).nodeID==receive_packet.source);

if isempty(index)
    % The node is not in the table

    % if the table size has reached its capacity,
    if (length(protocol_params.neighbor_list(id).nodeID) >= protocol_params.neighbor_list(id).size)

        % Make sure the current parent's frequency doesn't drop to 0
        if all_mote.parent(id) ~= protocol_params.invalid_parent
            [r,c]=find(protocol_params.neighbor_list(id).nodeID ==all_mote.parent(id));
            if protocol_params.neighbor_list(id).freq(c) == 0
                protocol_params.neighbor_list(id).freq(c) = 1;    
            end
        end

        % Is there any entry with freq == 0
        [empt_val, empty_index]=find(protocol_params.neighbor_list(id).freq == 0);
        %   if yes, put the new node into this entry
        if ~isempty(empty_index)            
            feval(protocolName, 'new_neighbor_entry', empty_index(1), id, receive_packet);            
            protocol_params.neighbor_list(id).freq(empty_index(1)) = 1;            
        else
        %   else decrement all counter by 1 and drop this new node
            for i=1:protocol_params.neighbor_list(id).size
                if (protocol_params.neighbor_list(id).freq(i) > 0)
                    protocol_params.neighbor_list(id).freq(i) = protocol_params.neighbor_list(id).freq(i) - 1;
                    % Avoid making parent's frequency count to drop to 0
                    if (protocol_params.neighbor_list(id).nodeID(i) == all_mote.parent(id) &...
                            protocol_params.neighbor_list(id).freq(i) == 0)
                        protocol_params.neighbor_list(id).freq(i) = 1;
                    end

                    % We can delete this entry now, but we choose to hold on to it
                    %if protocol_params.neighbor_list(id).freq(i) == 0
                    %    protocol_params.neighbor_list(id).token.id(i) = 0;
                    %    protocol_params.neighbor_list(id).token.nodeInfo(i) = 0;
                    %end
                else
                    disp('BAD');    
                end
            end
        end
    else
        % Table still have space, just put the node into the next empty space in the table.
        protocol_params.neighbor_list(id).freq(length(protocol_params.neighbor_list(id).nodeID)+1) = 1;   
        feval(protocolName, 'new_neighbor_entry', length(protocol_params.neighbor_list(id).nodeID)+1, id, receive_packet);            
    end
else
    % Node is in the table, just increment the frequency count
    protocol_params.neighbor_list(id).freq(index) = protocol_params.neighbor_list(id).freq(index) + 1;    
end
result = protocol_params.neighbor_list(id);



