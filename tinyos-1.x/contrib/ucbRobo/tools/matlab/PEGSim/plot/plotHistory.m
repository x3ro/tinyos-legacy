function plotHistory
% Plots the history of the packet reception in the last simulation
%
% history.delay is a 1:(T/dT) cell array of delay vectors
% delay < 0 means no transmission

global plotState;
global history;
global dT;

transVec = -2*ones(1,size(history.delay,2));
% Packet Processing
for i = 1:size(history.delay,2)
    d = history.delay{i};
    if (~isempty(d) && max(d) >= 0)
        d = d(d >= 0);
    else
        d = -1;
    end
    transVec(i) = min(d);
end

recvVec = -2*ones(1,size(history.rcvpkts,2));
for i = 1:size(history.rcvpkts,2)
    %arriveTime is 1st field, timestamp is 6th field
    if (~isempty(history.rcvpkts{i}))
        d = (history.rcvpkts{i}(1,:) - history.rcvpkts{i}(6,:))/dT;
    else
        d = -1;
    end
    recvVec(i) = min(d);
end

figure(plotState.PktHistfignum);
Tvec = (1:size(history.delay,2))*dT;
subplot(2,1,1);
stem(Tvec,transVec);
ylabel('minimum delay of trans packets.');
xlabel('time');
title('Pkt Transmission Plot.  -1 means no pkts.');


subplot(2,1,2);
stem(Tvec,recvVec);
ylabel('minimum delay of recv packets.');
xlabel('time');
title('Pkt Reception Plot.  -1 means no pkts.');