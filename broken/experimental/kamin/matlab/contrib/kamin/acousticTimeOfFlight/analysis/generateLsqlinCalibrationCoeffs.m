function coefficients=generateLsqlinCalibrationCoeffs(rangingData, varargin)
%coefficients=generateLsqlinCalibrationCoeffs(rangingData, polynomialDegree)
%
%The first argument is a n x n cell array where n is the number of nodes.
%Each element ij of the cell array is a k x 2 x t matrix where k is the number of
%distance estimates between nodes i and j.
%Each k x 2 array is indexed by t where t indicates time.  You can think of 
%time for ij as indicating that motes ij haven't moved during time t.
%For each time, each row is a new distance estimate.  The first column 
%is the true distance and the second column is the estimated distance.  
%If the true distance is not known, the first column should be -1.
%
%The second argument is also a n x n cell array.  Each element ij is an array of length t.
%Each value at t is either 0 or 1, indicating whether the true distance at this time should be
%used in calibration or not.  If the knowledge matrix fails to indicate either way,
%the true distance will be used.  (Naturally, knowledgeMatrix must be symmetric).
%
%For those distance estimates where the true distance is known, this lin prog will 
%choose node parameters that minimize the error.  
%
%For those distance estimates ij where the true distance is not known, this lin prog will 
%choose parameters that minimize the inconsistency between ij and ji, where ji is the opposite
%distance at the same time t.  
%
%The third argument is the degree of the polynomial that should be used as a calibration function.
%
%The return parameter is an array of size n x polynomialDegree.
%Sub-array coefficients(i:i+polynomialDegree) are the polynomial coefficients for transmitter i.
%Sub-array coefficients(i+polynomialDegree+1:i+polynomialDegree*2) are the coefficients for receiver i.
%Note that the above expression can by used with POLYVAL.

%parse arguments
if length(varargin)>0
    polynomialDegree = varargin{1};
else
    polynomialDegree= 1; %default to linear regression
end

%check arugments
[n c t dummy] = size(rangingData);
if n~=c
    error('Your distance matrix must be square')
end

%I will create the matrices f and A and b as described in the linprog help files

%x is the vector of variables.  The first polynomialDegree*n*2 elements are the polynomial
%coefficients of each node (transmitter first, then receiver).  The last n^2 elements
%are the Zij coefficients introduced to minimize the absolute value.
params = [zeros(1,polynomialDegree+1)];
x = zeros(1, length(params)*2*n);

%C is the coefficients of the objective function and d is the obj vector
C=zeros(1,length(x));
d = [0];
rowobj=0;

%A is the coefficient matrix for inequality constraints, b is the constants
A=zeros(1,length(x)); %initialize to one row, add values of all rows later
B=[0];
row=0;

%Aeq is the coefficient matrix for equality constraints
Aeq=zeros(1,length(x)); %initialize to one row, add values of all rows later
beq=[0];
roweq=0;

rangingData = rangingData./max(max(max(max(rangingData))));

%For each transmitter receiver pair
%if the true distance is known, add two equations
%otherwise add two other equations
for transmitter=1:n
    for receiver=1:n
        for time = 1:t
            if rangingData(transmitter, receiver, time, 1)>0 & rangingData(transmitter, receiver, time, 2)~=0 %if we know the distance, minimize error to known
                rowobj=rowobj+1;
                C(rowobj,:) = polynomialCalibrationFunction(rangingData(transmitter, receiver, time, 2),transmitter,receiver,polynomialDegree, size(rangingData,1)*(polynomialDegree+1)+size(rangingData,2)*(polynomialDegree+1));
                d(rowobj) = rangingData(transmitter, receiver, time, 1); 
            elseif rangingData(receiver, transmitter, time, 2)~=0 & rangingData(transmitter, receiver, time, 2)~=0%otherwise maximize consistency to reverse estimate
                rowobj=rowobj+1;
                C(rowobj,:) = polynomialCalibrationFunction(rangingData(transmitter, receiver, time, 2),transmitter,receiver,polynomialDegree, size(rangingData,1)*(polynomialDegree+1)+size(rangingData,2)*(polynomialDegree+1));
                C(rowobj,:) = C(rowobj,:)-polynomialCalibrationFunction(rangingData(receiver, transmitter, time, 2),receiver,transmitter,polynomialDegree, size(rangingData,1)*(polynomialDegree+1)+size(rangingData,2)*(polynomialDegree+1));
                d(rowobj) = 0; 
            end
        end
    end
end

for i=1:size(rangingData,1)*(polynomialDegree+1)
    rowobj=rowobj+1;
    C(rowobj,i*2-1) = 1;
    d(rowobj) = .5;
end




A(1,:)=ones(1,length(x));
B(1) = length(x);

% row=0;
% for transmitter = 1:size(rangingData,1)
%     for receiver = 1:size(rangingData,2)
%         for time = 1:size(rangingData,3) %assume TOF is a vector of TOF_DISTANCE structures
% 	        if rangingData(transmitter, receiver, time, 2)~=0
%                 
%                 if rangingData(transmitter, receiver, time, 1)>=0; %if we know the distance, minimize error to known
%                     row=row+1;
%                     A(row,:) = polynomialCalibrationFunction(rangingData(transmitter, receiver, time, 2),transmitter,receiver,polynomialDegree, size(rangingData,1)*(polynomialDegree+1)+size(rangingData,2)*(polynomialDegree+1));
%                     B(row) = 3*rangingData(transmitter, receiver, time, 1); 
%                 elseif rangingData(receiver, transmitter, time, 2)~=0%otherwise maximize consistency to reverse estimate
%                     row=row+1;
%                     A(row,:) = polynomialCalibrationFunction(rangingData(transmitter, receiver, time, 2),transmitter,receiver,polynomialDegree, size(rangingData,1)*(polynomialDegree+1)+size(rangingData,2)*(polynomialDegree+1));
%                     A(row,:) = A(row,:)-3*polynomialCalibrationFunction(rangingData(receiver, transmitter, time, 2),receiver,transmitter,polynomialDegree, size(rangingData,1)*(polynomialDegree+1)+size(rangingData,2)*(polynomialDegree+1));
%                     B(row) = 0; 
%                 end
%             end
%         end
%     end  
% end   

% for i=1:size(rangingData,1)*(polynomialDegree+1)
%     row=row+1;
%     A(row,i*2-1) = 1;
%     B(row) = .5;
% end

%for every set of 3 nodes, there are eight directed triangles.
%For each directed triangle, there are 3 inequalities (one for each side), using distances if known
%However, we are going to ignore 3 out of every 4 triangles.  Ie. for each
%ijk we are only going to use triangles ij-jk-ki and ji-jk-ki because of our assumption that
%jk=kj and ki=ik (so there is no need to consider variations of these as
%seperate constraints).
% for i=1:n
%     for j=1:n
%         for k=1:n
%             if i~=j & j~=k & k~=i
%                 distancesij= distanceMatrix{i,j};
%                 distancesjk= distanceMatrix{j,k};
%                 distanceski= distanceMatrix{k,i};
%                 if ~isempty(distancesij) & ~isempty(distancesjk) & ~isempty(distanceski)
%                     for each time that these three are a triangle
%                     for t = 1:min(min(size(distanceij,3), size(distancejk,3)), size(distanceki,3))
%                         if we don't know ij distance
%                         if distancesij(1,1,t)<0 |length(knowledgeMatrix{i,j}) < t | knowledgeMatrix{i,j}(t)<=0
%                             add a new row to the constants
%                             row = row+1;
%                             b(row)=0;
%                             
%                             add this edge to the new inequality
%                             A(row, 1:size(x)) = calibrationFunction(distancesij(1,2,t),i,j,polynomialDegree, size(x), size(params));
%     
%                             if we don't know jk distance
%                             if distancesjk(1,1,t)<0 | length(knowledgeMatrix{j,k})<t | knowledgeMatrix{j,k}(t)<=0
%                                 A(row, 1:size(x)) = A(row, 1:size(x))-calibrationFunction(distancesjk(1,2,t),j,k,polynomialDegree, size(x), size(params));
%                             else
%                                 b(row)=b(row)+distancesjk(1,1,t);
%                             end
% 
%                             if we don't know ki distance
%                             if distanceski(1,1,t)<0 | length(knowledgeMatrix{k,i})<t | knowledgeMatrix{k,i}(t)<=0
%                                 A(row, 1:size(x)) = A(row, 1:size(x))-calibrationFunction(distanceski(1,2,t),k,i,polynomialDegree, size(x), size(params));
%                             else
%                                 b(row)=b(row)+distanceski(1,1,t);
%                             end
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end

coefficients=lsqlin(C,d,A,B,[],[],-20*ones(length(x),1),20*ones(length(x),1),repmat([.5; 0],2*size(rangingData,1),1));

