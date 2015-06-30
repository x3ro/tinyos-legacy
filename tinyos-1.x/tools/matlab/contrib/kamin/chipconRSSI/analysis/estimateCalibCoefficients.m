function calibrationCoeffs=estimateCalibCoefficients(rangingData, defaultCoeffs)
%calibrationCoeffs=estimateTOFCalibrationCoefficients(rangingData, defaultCoeffs)
%
%This will take the readings that are stored in rangingData and 
%simultaneously calculate the calibration coefficients for each transmitter and receiver
%using joint calibration
%
%ranging data is a matrix of the form:
%[receiverID transmitterID estimatedDistance trueDistance]
%
%calibrationCoeffs is a matrix of the form:
%[receiv1Coeff1 receiv2Coeff1 ... transmit1Coeff1 transmit2Coeff1 ... 
%   receiv1Coeff2 receiv2Coeff2 ... transmit1Coeff2 transmit2Coeff2 ...] 
%where the calibration function is:
%estDist*transCoeff1 + estDist*receivCoeff1 + transCoeff2 + receivCoeff2 = trueDist

if length(rangingData)==0 error('no RSSI data in variable rangingData'); return; end

%first, figure out who the transmitters and receivers are
transmitters=sort(rangingData(:,2));
uniques=[find(diff(transmitters)>0); length(transmitters)];
transmitters=transmitters(uniques)';
receivers=sort(rangingData(:,1));
uniques=[find(diff(receivers)>0); length(receivers)];
receivers=receivers(uniques)';

%initialize a couple of things
t=length(transmitters);
r=length(transmitters);
%n=max(t,r); %n is the max of all node numbers
%n=16; %n is the number of nodes
n=length(defaultCoeffs)/4;

%now, setup a system of equations of the form Ax=B

%initialize the A matrix so that we know how big it will be
%the default params for any node are [0.5 0]

    %linear regression
%A=zeros(size(rangingData,1),2);

    %joint calibration with linear regression
A=zeros(size(rangingData,1),4*n);

%for each transmitter
row=1;
for i=1:size(rangingData,1);
    %for each reading that we get, add the equation 
    %estDist*transCoeff1 + estDist*receivCoeff1 + transCoeff2 + receivCoeff2 = trueDist
    %using the equation Ax=B

    %linear regression
%     A(row,1) = 1; %the estimated distance
%     A(row,2) = rangingData(row,3);
    
    %joint calibration with linear regression
    A(row,rangingData(row,1)) = rangingData(row,3); %the estimated distance
    A(row,n+rangingData(row,2)) = rangingData(row,3);
    A(row,n*2+rangingData(row,1)) = 1;
    A(row,n*3+rangingData(row,2)) = 1;
    
    B(row)=rangingData(row,4); %the true distance
    row=row+1;
end   

%now solve the equations using least squares
%initX = [-0.5*ones(2*n,1); zeros(2*n,1)];
calibrationCoeffs=lsqr(A,B',1e-9,200);

%make sure that the calibration coeffs for nodes that weren't present in
%the calculation are set to the default of [0.5 0]
for i=1:n
    if ~any(receivers==i)
        calibrationCoeffs(i) = defaultCoeffs(i); 
        calibrationCoeffs(n*2+i) = defaultCoeffs(n*2+i);
    end
    if ~any(transmitters==i)
        calibrationCoeffs(n+i) = defaultCoeffs(n+i);
        calibrationCoeffs(n*3+i) = defaultCoeffs(n*3+i);
    end
end

        
    