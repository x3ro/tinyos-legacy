[r c] = size(TOF_DISTANCE.onsetTOF);

if ishold
    figure
end
lstyle = {'--.k','--+k','--*k','--ok','--xk','--.b','--+b','--*b','--ob','--xb','--.g','--+g','--*g','--og','--xg','--.r','--+r','--*r','--or','--xr','--.c','--+c','--*c','--oc','--xc','--.m','--+m','--*m','--om','--xm','--.y','--+y','--*y','--oy','--xy'};
leg={};
for k=1:max(r,c)
    leg{k}=num2str(k);
end

%store the old calibration information
oldReceiverCalib = TOF_DISTANCE.receiverCalib;
oldTransmitterCalib = TOF_DISTANCE.transmitterCalib;


polyOrder=1;

for i=1:r

    %make a fit for this node's microphone
	for k=1:max(r,c)
        plot(0,0,lstyle{k})
        hold on
	end

    for j = 1:c

        %for each transmitter
        if length(TOF_DISTANCE.onsetTOF{i,j})>5
            %get that transmitter's distance
            [xi, yi, zi] = getLocation(i);
            [xj, yj, zj] = getLocation(j);
            dist= sqrt( (xi-xj)^2 + (yi-yj)^2 + (zi-zj)^2 );

            %get that node's distance estimate
            TOF=[];
            DIST=[];
            data = [TOF_DISTANCE.onsetTOF{i,j}];
            TOF = data*.25;
            DIST= (TOF-100)*.0347;
	        distEstimate=[];
            for k = 1:length(DIST)
                window = timeWindow(DIST(1:k), 30); %windowSize=30
                medn = median(window);
                range=.0007*medn^2+.025*medn+30;
                window = removeOutsideOf(window, medn-range, medn);
                m = min(window);
                distEstimate(k) = m;%m-0.0006*m^2 -.2505*m+1.1741;
            end
            
            %adjust the estimate using calibration info of transmitter
            finalEstimate = mode(max(1, round(distEstimate)));
            calibratedTransmitterError = polyval(TOF_DISTANCE.transmitterCalib{j},finalEstimate);
            calibratedReceiverError = polyval(TOF_DISTANCE.receiverCalib{i},finalEstimate);
            estimates=finalEstimate-calibratedTransmitterError;%-calibratedReceiverError;
            
            plot(dist, estimates, lstyle{j})
        end
    end 
    plot(0:250,0:250,'-')
	hold off
	title([ num2str(i) ' receiving'])
	if ~isempty(leg)
        legend(leg);
    end
	pause
end   


for i=1:r

    %make a fit for this node's microphone
	for k=1:max(r,c)
        plot(0,0,lstyle{k})
        hold on
	end

    for j = 1:c

        %for each transmitter
        if length(TOF_DISTANCE.onsetTOF{i,j})>5
            %get that transmitter's distance
            [xi, yi, zi] = getLocation(i);
            [xj, yj, zj] = getLocation(j);
            dist= sqrt( (xi-xj)^2 + (yi-yj)^2 + (zi-zj)^2 );

            %get that node's distance estimate
            TOF=[];
            DIST=[];
            data = [TOF_DISTANCE.onsetTOF{i,j}];
            TOF = data*.25;
            DIST= (TOF-100)*.0347;
	        distEstimate=[];
            for k = 1:length(DIST)
                window = timeWindow(DIST(1:k), 30); %windowSize=30
                medn = median(window);
                range=.0007*medn^2+.025*medn+30;
                window = removeOutsideOf(window, medn-range, medn);
                m = min(window);
                distEstimate(k) = m;%m-0.0006*m^2 -.2505*m+1.1741;
            end
            
            %adjust the estimate using calibration info of transmitter
            finalEstimate = mode(max(1, round(distEstimate)));
%            calibratedTransmitterError = polyval(TOF_DISTANCE.transmitterCalib{j},finalEstimate);
            calibratedReceiverError = polyval(TOF_DISTANCE.receiverCalib{i},finalEstimate);
            estimates=finalEstimate-calibratedReceiverError;%-calibratedTransmitterError;
            
            plot(dist, estimates, lstyle{j})
        end
    end 
    plot(0:250,0:250,'-')
	hold off
	title([ num2str(i) ' receiving'])
	if ~isempty(leg)
        legend(leg);
    end
	pause
end   

