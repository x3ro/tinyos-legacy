function calibrationCoeffs = generateNaiveCalibrationCoeffs(rangingData, varargin)
%calibrationCoeffs = generateNaiveCalibrationCoeffs(rangingData, varargin)
%
%this function uses the data in rangingData to calculate calibration
%coefficients for each sounder/microphone.   It does this by choosing
%parameters for each device that minimize the difference between the 
%estimated distances and the true distances (in the least squares sense).
%If the true distances are not known (indicated with -1), it minimizes the difference between
%the estimated distances and the estimated backwards distances.
%
%rangingData is a matrix as follows:
%
%rangingData(transmitter, receiver, time, [truth estimate])
%
%This file assumes that there are no false positives in the data, which
%would really screw up the calibration coefficients.

%parse arguments
if length(varargin)>0
    polynomialDegree = varargin{1};
else
    polynomialDegree= 1; %default to linear regression
end

rangingData = rangingData./max(max(max(max(rangingData))));

A=[];
B=[];
row=0;

if any(any(any(rangingData(:,:,:,1)>0)))
	for transmitter = 1:size(rangingData,1)
        for receiver = 1:size(rangingData,2)
            for time = 1:size(rangingData,3) %assume TOF is a vector of TOF_DISTANCE structures
		        if rangingData(transmitter, receiver, time, 2)~=0                
                    if rangingData(transmitter, receiver, time, 1)>0 %if we know the distance, minimize error to known
                        row=row+1;
                        A(row,1:(polynomialDegree+1)*2) = repmat(createPolynomial(rangingData(transmitter, receiver, time, 2),polynomialDegree),1,2);
                        B(row) = rangingData(transmitter, receiver, time, 1); 
                    end
                end
            end
        end  
	end   
	
% 	row=row+1;
% 	A(row,1) = 1;
% 	B(row) = .5;
        
	%find the calibration coefficients
    calibrationCoeffs=lsqr(A,B',1e-9,200,[],[],[.5; 0; 0.5; 0]);
	%calibrationCoeffs=lsqr(A,B',1e-9,200,[],[],[]);
	calibrationCoeffs = repmat(calibrationCoeffs', 1,size(rangingData,1));
else
    calibrationCoeffs = repmat([.5; 0; 0.5; 0], 1,size(rangingData,1));
end
