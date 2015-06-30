function t=addEmpiricalRangingData(MONITOR_DATA, topology, t, epsilon, filters)
%this function takes the empirical ranging data from MONITOR_DATA, which is
%the format we used to collect the ultrasound ranging data, and topology,
%which is the format that we store the topology info in, and replaces
%all ranging estimates in t with real estimates from the MONITOR_DATA.
%
%this assumes that the coordinate system for t is in cm.



%the first thing to do is to make a big array of all data in the
%MONITOR_DATA structure to have the form:
%[trueDistance estimatedDistance ]

if nargin<4 | isempty(epsilon)
    epsilon=.03; %2 centimeters
end
if nargin<5 | isempty(filters)
    filters = {{'upperBound',23000}, {'medianTube',23000/6*.10}, {'minReadings',4}, {'minimum'}};
end

filteredData = filterate(MONITOR_DATA, filters);
calibratedData = calibrate(filteredData, topology, 'uniform');
[trueDists, estDists, ex, tx, rx] = getErrors(calibratedData, topology);
% [trueDists, estDists, ex, tx, rx] = getErrors(MONITOR_DATA, topology);


%The second thing is, for each distance in t, to randomly choose a ranging
%estimate from the big array created above and replace the corresponding
%entry in t.distanceMatrix and t.connectivityMatrix with the second and
%third columns.

for i=1:length(t)
    for txr=1:size(t(i).distanceMatrix,1)
        for rxr=1:size(t(i).distanceMatrix,2)
            if rxr==txr
                t(i).connectivityMatrix(txr,rxr)=1;
                t(i).kd(txr, rxr)=0;
            elseif rxr<txr
                t(i).connectivityMatrix(txr,rxr)=t(i).connectivityMatrix(rxr,txr);
                t(i).kd(txr, rxr)=t(i).kd(rxr, txr);
            else

                d= t(i).distanceMatrix(txr,rxr);
                candidates = find(trueDists > d-epsilon & trueDists < d+epsilon);
                if isempty(candidates)
                    %if there are no such distances in the real data
                    t(i).connectivityMatrix(txr,rxr)=0;
                    t(i).kd(txr,rxr)=-1;
                else
                    candidate = candidates(ceil(rand*length(candidates)));
                    if estDists(candidate)==0
                        %if there is a distance, but we randomly chose a failed pair
                        t(i).connectivityMatrix(txr,rxr)=0;
                        t(i).kd(txr,rxr)=-1;
                    else
                        %if there is a distance, use the error of it on this distance estimate
                        t(i).connectivityMatrix(txr,rxr)=1;
                        t(i).kd(txr,rxr)=t(i).distanceMatrix(txr,rxr)+ ( estDists(candidate) - trueDists(candidate) );
                    end
                end
            end
        end
    end
end
                



function [true, est, ex, tx, rx, sample] = getErrors(data, topology)
true=[]; est=[]; ex=[]; tx=[]; rx=[]; sample=[];
for e=1:length(data)
    %for each transmitter
    for t = 1:size(data(e).rangingData,1)
        %for each receiver
        for r = 1:size(data(e).rangingData,2)
            %for each chirp
            for i = 1:size(data(e).rangingData,3)
%                if data(e).rangingData(t,r,i)~=0 & trueDist(t, r, e, topology)~=0
                if trueDist(t, r, e, topology)~=0
                    est = [est data(e).rangingData(t,r,i)];
                    true = [true trueDist(t, r, e, topology)];
                    ex = [ex e];
                    tx = [tx t];
                    rx = [rx r];
                    sample = [sample i];
                end
            end
        end
    end
end

function distance = trueDist(transmitter, receiver, experimentNumber, topology)
%this function gives the distance between a transmitter and receiver in a
%particular topology during a particular experiment
t=find([topology.experiment(experimentNumber,:)]==transmitter);
r=find([topology.experiment(experimentNumber,:)]==receiver);
distance = topology.distance(t,r);
