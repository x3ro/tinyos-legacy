function [delay, packets] = SNSim_simple(NoDelayFlag)
% Simple Sensor Network Simulator
% Runs simulation of evader detection and routing of information through
% the sensor network to the pursuer.
% 
% See SNSimInit_simple for more details
%
% Input: global variables P, E, SN, amd T
% Output: packets k*n matrix, k is dim of fields in packet, n is number
%                 of packets
%                 [detect_sensor; x; y; send_sensor; timestamp]
%         delay   number of time steps until packet transmission
global P; % pursuer structure
global E; % evader structure
global SN; % sensor network structure
global T;

if (nargin < 1)
    NoDelayFlag = false;
end

detected = [];
% Detection
for i = 1:E.n % this is unnecessary until we augment the dimension of E
    x = E.pos(1,end);
    y = E.pos(2,end);
    for j = 1:SN.n
      dX = x - SN.nodes(1,j);
      dY = y - SN.nodes(2,j);
      R_s = SN.nodes(3,j);
      r = sqrt(dX*dX + dY*dY);
      if (rand < (R_s - r)/R_s)
        % detection!
        detected(:,end+1) = [i; j; x+randn*SN.ob_noise; y+randn*SN.ob_noise];
      end
    end
end


% Transmission
delay = [];
packets = [];
% For now, route everything to pursuer 1 (there's only 1 pursuer)
x = P.pos(1,end);
y = P.pos(2,end);
A = [x - SN.nodes(1,:); y - SN.nodes(2,:)];
A(1,:) = A(1,:).*A(1,:);
A(2,:) = A(2,:).*A(2,:);
A = sqrt([1 1] * A);
[r_min closeNode] = min(A);

% step-by-step simulation of packet transmission
for i = 1:size(detected,2)
  packets = [packets [detected(2:4,i) ; closeNode ; T]];
  route = SN.routePath{detected(2,i),closeNode};
  
  if (length(route) ~= 0) && (route(end) ~= closeNode)   % Sanity Check
      disp('Problem with SN route generation');
      disp(sprintf('route(end) = %d, closeNode = %d, transmit from %d',route(end), closeNode, detected(2,i)));
  end
  
  if (length(route) == 0) && (detected(2,i) ~= closeNode)
      delay = [delay (-1)]; % no transmission since no route
  else
      ttl = SN.rt_num;
      currNode = detected(2,i);
      k = 1;
      while (ttl > 0) && (k <= length(route))
          if (rand < SN.linkP(currNode,route(k)))
              currNode = route(k);
              k = k+1;
          end
          ttl = ttl - 1;
      end
      if (currNode == closeNode) % handles node to itself trans as well
            % same condition as k > length(route)
          % last hop calculation
          R_r = SN.nodes(4,closeNode);
          p_lastHop = (R_r-r_min)/R_r;
          while (ttl > 0) && (rand > p_lastHop)
              ttl = ttl - 1; % doesn't decrement on success **
          end
      end %currNode == closeNode...
      if (ttl > 0)
          % successful transmission!
          if (NoDelayFlag)
              delay = [delay 0];
          else
              delay = [delay (SN.rt_num - ttl + 1)]; % +1 for comment ** above
          end
      else
          % no transmission
          delay = [delay (-1)];
      end %ttl...
  end %length(route)...
end
