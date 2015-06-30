function coefficients=linProgCalibrate(distanceMatrix, varargin)
%coefficients=linProgCalibrate(distanceMatrix, knowledgeMatrix, polynomialDegree)
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
if length(varargin)>1
    polynomialDegree = varargin{2};
else
    polynomialDegree= 1; %default to linear regression
end
if length(varargin)>0
    knowledgeMatrix = varargin{1};
end

%check arugments
[r c] = size(distanceMatrix);
[rk ck] = size(knowledgeMatrix);
if r~=c | rk~=ck 
    error('Your distance and knowledge matrices must be square')
else
    n=r;%n is the number of nodes in the network
end
if r~=rk | c~=ck
    error('Your distance and knowledge matrices must be the same size')
end

%I will create the matrices f and A and b as described in the linprog help files

%x is the vector of variables.  The first polynomialDegree*n*2 elements are the polynomial
%coefficients of each node (transmitter first, then receiver).  The last n^2 elements
%are the Zij coefficients introduced to minimize the absolute value.
params = [zeros(1,polynomialDegree+2)];
x = zeros(1, size(params)*2*n);

%f is the coefficients of the objective function (minimize the Z's)
f=zeros(size(x),1);

%A is the coefficient matrix for inequality constraints, b is the constants
A=zeros(1,size(x)); %initialize to one row, add values of all rows later
b=[0];
row=0;

%Aeq is the coefficient matrix for equality constraints
Aeq=zeros(1,size(x)); %initialize to one row, add values of all rows later
beq=[0];
roweq=0;

frequencyVariableIndices=zeros(32); %this variable tells me which x veriable is the difference between frequencies for i and j

%For each transmitter receiver pair
%if the true distance is known, add two equations
%otherwise add two other equations
for i=1:n
    for j=1:n
        distances= distanceMatrix{i,j};
        distancesReverse= distanceMatrix{j,i};
        if ~isempty(distances) & i~=j
            for t=1:size(distances,3) %for each time 
                %if the distance between i and j is known at time t
                if (length(knowledgeMatrix{i,j}<t) | knowledgeMatrix{i,j}(t)>0) & distances(1,1,t) >=0                 
                    currentDistance = distances(1,1,t);
                    for sample=1:size(distances,1)
                        %add two inequalities to the program

                        %f(tij, Ti, Rj)-dij <=Zij1
                        addDummyVariable;%(add Zij1)
                        row=row+1;%add inequality
                        f(end)=1; %minimize that dummy variable
                        A(row,end) = -1; 
                        A(row, 1:size(x)) = calibrationFunction(distances(sample,2,t),i,j,polynomialDegree, size(x), size(params));
                        b(row) = distanceEstimate;
  
                        %f(tji, Tj, Ri)-dji <=Zij2
                        addDummyVariable;%(add Zij2)
                        row=row+1;%add inequality
                        f(end)=1; %minimize that dummy variable
                        A(row,end) = -1; 
                        A(row, 1:size(x)) = -calibrationFunction(distances(sample,2,t),i,j,polynomialDegree, size(x), size(params));
                        b(row) = -distanceEstimate;
                    end
                %if the distance between i and j is NOT known then if i < j
                %add a new inequality for each reading in the reverse direction
                %(if i>=j, we already added all of the inequalities)
                else if i < j & ~isempty(distancesReverse) & size(distancesReverse,3) >= t
                    for sample=1:size(distances,1)
                        for sampleReverse=1:size(distancesReverse,1)
	
                            %f(tij, Ti, Rj)-f(tji, Tj, Ri) <=Zij
                            addDummyVariable; %add Zij
                            row=row+1;%add inequality
                            f(end)=1; %minimize that dummy variable
                            A(row, 1:size(x)) = calibrationFunction(distances(sample,2,t),i,j,polynomialDegree, size(x), size(params));
                            A(row, 1:size(x)) =A(row, 1:size(x)) - calibrationFunction(distancesReverse(sample,2,t),j,i,polynomialDegree, size(x), size(params));
                            A(row,end) = -1; 
                            b(row) = 0;
	
                            %f(tji, Tj, Ri)- f(tij, Ti, Rj) <=Zji
                            addDummyVariable; %add Zji
                            row=row+1;%add inequality
                            f(end)=1; %minimize that dummy variable
                            A(row, 1:size(x)) = -calibrationFunction(distances(sample,2,t),i,j,polynomialDegree, size(x), size(params));
                            A(row, 1:size(x)) =A(row, 1:size(x)) + calibrationFunction(distancesReverse(sample,2,t),j,i,polynomialDegree, size(x), size(params));
                            A(row,end) = -1; 
                            b(row) = 0;
                        end
                    end
                end
            end
        end
    end
end
            
%for every set of 3 nodes, there are eight directed triangles.
%For each directed triangle, there are 3 inequalities (one for each side), using distances if known
%However, we are going to ignore 3 out of every 4 triangles.  Ie. for each
%ijk we are only going to use triangles ij-jk-ki and ji-jk-ki because of our assumption that
%jk=kj and ki=ik (so there is no need to consider variations of these as
%seperate constraints).
for i=1:n
    for j=1:n
        for k=1:n
            if i~=j & j~=k & k~=i
                distancesij= distanceMatrix{i,j};
                distancesjk= distanceMatrix{j,k};
                distanceski= distanceMatrix{k,i};
                if ~isempty(distancesij) & ~isempty(distancesjk) & ~isempty(distanceski)
                    %for each time that these three are a triangle
                    for t = 1:min(min(size(distanceij,3), size(distancejk,3)), size(distanceki,3))
                        %if we don't know ij distance
                        if distancesij(1,1,t)<0 |length(knowledgeMatrix{i,j}) < t | knowledgeMatrix{i,j}(t)<=0
                            %add a new row to the constants
                            row = row+1;
                            b(row)=0;
                            
                            %add this edge to the new inequality
                            A(row, 1:size(x)) = calibrationFunction(distancesij(1,2,t),i,j,polynomialDegree, size(x), size(params));
    
                            %if we don't know jk distance
                            if distancesjk(1,1,t)<0 | length(knowledgeMatrix{j,k})<t | knowledgeMatrix{j,k}(t)<=0
                                A(row, 1:size(x)) = A(row, 1:size(x))-calibrationFunction(distancesjk(1,2,t),j,k,polynomialDegree, size(x), size(params));
                            else
                                b(row)=b(row)+distancesjk(1,1,t);
                            end

                            %if we don't know ki distance
                            if distanceski(1,1,t)<0 | length(knowledgeMatrix{k,i})<t | knowledgeMatrix{k,i}(t)<=0
                                A(row, 1:size(x)) = A(row, 1:size(x))-calibrationFunction(distanceski(1,2,t),k,i,polynomialDegree, size(x), size(params));
                            else
                                b(row)=b(row)+distanceski(1,1,t);
                            end
                        end
                    end
                end
            end
        end
    end
end

x=linprog(f,A,b);

