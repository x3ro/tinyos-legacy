function test
%testing script; delete and replace at will

global P; % pursuer structure
global E; % evader structure
global SN; % sensor network structure
global T;

if (nargin < 1)
    NoDelayFlag = false;
end

x = 1;
y = 1;
detected = [];
detected(:,end+1) = [1; 13; x+randn*SN.ob_noise; y+randn*SN.ob_noise];

% Transmission
delay = [];
packets = [];

closeNode = 34;
r_min = norm(P.pos(1:2,50) - SN.nodes(1:2,closeNode));

for i = 1:size(detected,2)
  packets = [packets [detected(2:4,i) ; closeNode ; T]];
      route = SN.routePath{detected(2,i),closeNode};

  if (length(route) == 0) && (detected(2,i) ~= closeNode)
      delay = [delay (-1)]; % no transmission, no route
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
      if (isempty(route) || (currNode == route(end)))
          disp(sprintf('currNode == closeNode ? %d',currNode == closeNode));
          % last hop calculation
          R_r = SN.nodes(4,closeNode);
          b = SN.nodes(6,closeNode);
          p_lastHop = b/(b+r_min^SN.alphaR);
          while (ttl > 0) && ((r_min > R_r) || (rand > p_lastHop))
              ttl = ttl - 1; % doesn't decrement on success **
          end
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
          end %ttl
      else %isempty(route)...
          % no transmission
          delay = [delay (-1)];
      end
  end %length(route)...
end
