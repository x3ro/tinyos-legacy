function dummyData

global VIS;


% no dummy data
return;

dummy_route_tree = 0;
dummy_route_crumb = 1;
dummy_mag = 1;
dummy_agents = 1;
dummy_localization = 1;


%
% generate routing info
%
if dummy_route_tree
  % choose the leader
  if VIS.route.leader < 0
    VIS.route.leader = ceil(rand(1) * length( VIS.node ));
    VIS.node( VIS.route.leader ).parent = -2;
  end

  
  % find a parentless node, and connect it
  parentless = find([VIS.node.parent] == -1);
  if ~isempty(parentless) 
    connected = [VIS.route.leader ; find([VIS.node.parent] > -1)];
    p = connected( ceil(rand(1) * length(connected)) );
    n = parentless( ceil(rand(1) * length(parentless)) );
    VIS.node(n).parent = p;
  end
end


% 
% generate regular messages
%



%
% generate crumb info
%
if dummy_route_crumb
  for i = 1:VIS.num_pursuers

    len = length( VIS.crumb.agent(i).completed_src );

    % find the previous end of trail.  Create one if there is none
    if len == 0
      tail = ceil( VIS.num_nodes * rand(1) );
    else
      tail = VIS.crumb.agent(i).completed_dest( len );
    end 

    % create the message 
    text.dest = i+VIS.num_evaders; % FIXME: HACK. agent #s are first
    text.routing_origin = tail;
    text.routing_address = ceil(VIS.num_nodes * rand(1));

    % finish off the crumb trail.  Note we use ==, rather than >, since
    % the actual end of the trail will not be triggered until the 
    % next msg2pursuer() call.
    if len == 10
      guiMessageHandler('msg2pursuer',text);
    else 
      guiMessageHandler('msg2base',text);
    end

  end

end




% generate mag readings

if dummy_mag
  for k = 1:2
    i = ceil(VIS.num_nodes * rand(1));
    updateMagData(VIS.nodeIdx(i),8*rand(1)+2);
  end
end




% generate pursuer evader movements

if dummy_agents
  width = floor(sqrt( VIS.num_nodes ));

  for i = 1:VIS.num_agents

    % set the real position
    if isempty( VIS.agent(i).real_pos ) | isnan(VIS.agent(i).real_pos(1))
      VIS.agent(i).real_pos = width * rand(1,2);
    else
      VIS.agent(i).real_pos = VIS.agent(i).real_pos + .4*(rand(1,2) - ones(1,2)/2);
      if VIS.agent(i).real_pos(1) < -1
        VIS.agent(i).real_pos(1) = -1;
      end;
      if VIS.agent(i).real_pos(1) > width
        VIS.agent(i).real_pos(1) = width;
      end;
      if VIS.agent(i).real_pos(2) < -1
        VIS.agent(i).real_pos(2) = -1;
      end;
      if VIS.agent(i).real_pos(2) > width
        VIS.agent(i).real_pos(2) = width;
      end;
    end

    % set the calc position to be a bit off the real
    VIS.agent(i).calc_pos = VIS.agent(i).real_pos - .3 * rand(1,2);
  end

  VIS.flag.agent_updated = 1;

end


if dummy_localization & ~isfield(VIS.node(1), 'anchor')
    for n = 1:VIS.num_nodes
        for i = 1:3
            m = ceil( rand(1) * VIS.num_nodes );
            VIS.node(n).anchor(i).nodeIdx = m;
            VIS.node(n).anchor(i).dist = 10*rand(1);
            
            m = ceil( rand(1) * VIS.num_nodes );
            VIS.node(n).neighbor(i).nodeIdx = m;
            VIS.node(n).neighbor(i).dist = 10*rand(1);
        end
    end
end