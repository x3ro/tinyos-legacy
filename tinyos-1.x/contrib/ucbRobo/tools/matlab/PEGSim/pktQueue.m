function rcvpkts = pktQueue(delay, packets)
%Simulates the delay in the network for the arrival of packets
%
% 1) Adds current packets to end of queue
% 2) remove packets from front of queue
%
% Output: [arriveTime ; packets]

global T;
global dT;
global queue; %so we can reset it

% only handle packets that are transmitted
arrived = find(delay >= 0);
arrDelay = delay(arrived);
arrPkts = packets(:,arrived);

arriveTime = T + dT*arrDelay;
newEntries = [arriveTime ; arrPkts];

if ~isempty(newEntries) % remove silly error messages
    queue = sortrows([queue newEntries]')';
end

if ~isempty(queue) % remove error messages
    % rounding error makes ~= and == not work
    rcvpkts = queue(:,find(queue(1,:) <= T));
    queue = queue(:,find(queue(1,:) > T));
else
    rcvpkts = [];
end
