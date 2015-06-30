function tof_calibration=estimateTOFCalibCoefficients(varargin)
%tof_calibration=estimateTOFCalibrationCoefficients()
%
%This will take the readings that are stored in TOF_CALIBRATION and 
%simultaneously calculate the calibration coefficients for each transmitter and receiver
%using joint calibration

global TOF_CALIBRATION
global MAX_NETWORK_DIMENSION

row=0;
r=max(TOF_CALIBRATION.transmitterIDs);
c=max(TOF_CALIBRATION.receiverIDs);
n=max(r,c); %n is the number of nodes we might have (the max of all node numbers)

%initialize the A matrix so that we know how big it will be
A(1,n*3+r)=0;
A(1,n*3+c)=0;

%for each transmitter
for i=1:r
	%for each receiver
	for j=1:c

        readings = TOF_CALIBRATION.readings{i,j};
        if ~isempty(readings)
            [readingsR readingsC] = size(readings);
            for k=1:readingsC
                if readings(1,k)~=0 & readings(2,k)~=0
                    %for each reading that we get, add the equation 
                    %reading*transCoeff1 + reading*receivCoeff1 + transCoeff2 + receivCoeff2 = trueDist
                    %using the equation Ax=B
                    
                    row=row+1;
                    
	                A(row,i) = readings(1,k);
                    A(row,n+j) = readings(1,k);
                    A(row,n*2+i) = 1;
                    A(row,n*3+j) = 1;
                    
                    B(row)=readings(2,k);
                end
            end
        end
    end 
end   

%now solve the equations using least squares
x=lsqr(A,B',1e-9,200);
%save it just in case
TOF_CALIBRATION.x=x;

%set the transmitter coeffiecients
for i=1:r
    TOF_CALIBRATION.transmitterCoefficients{i} = [x(i) x(n*2+i)];
end

%set the receivercoeffiecients
for i=1:c
    TOF_CALIBRATION.receiverCoefficients{i} = [x(n+i) x(n*3+i)];
end

save TOF_CALIBRATION
tof_calibration=TOF_CALIBRATION;

%plot the calibrated estimates
hold off
plot(B, A*x,'.b')
hold on
maxDistance = sqrt(2*MAX_NETWORK_DIMENSION^2);
plot([0:maxDistance],[0:maxDistance],'-r')
xlabel('True Distance (cm)')
ylabel('Estimated Distance (cm)')
title('Distance Estimates with Joint Calibration')
disp(['percent error: ' num2str(percentDistanceError( A*x, B))])