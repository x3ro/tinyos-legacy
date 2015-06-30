        function [list_ass_i,list_ass_j] = BottleneckAssigM2N(C)
% this function finds the modified bottleneck assignment in a MxN matrix C 
% M = number pursuers
% N = number evaders
% this problem is formulated as follows:
% let phi(i) a permutation of the vector (1,....,N), 
% and the corresponding cost vector c_phi = (C(1,phi(1)),C(2,phi(2)),....,C(n,phi(N)))
% sort this vector is ascending order c_phi_sorted, i.e 
% c_phi_sorted(i)<=c_phi_sorted(j) if i<j  i,j=1,....n 
% the modified bottleneck assignment find the optimal permutation phi_opt that solved the following
% optimization problem
% c_phi_opt_sorted(i)<= c_phi_sorted(i) for all i=1,....,N  for all possible permutations phi() 
% the standard bottleneck assignment problem guarantees only c_phi_opt_sorted(N)<= c_phi_sorted(N)
% the modified bottleneck assignment in the square matrix C can be solved iteratively by first
% finding the bottleneck assigment entry (i,j) in the original matrix of dimension N, then remove the
% corresponding row-column and iterate the next bottleneck assigment entry (i,j) in the 
% reduced matrix of dimension N-1, and so on.

% for details see "Linear assignment problems and Extensions" by R.E. Burkard and E. Cela (1998)

% Copyright by Luca Schenato and UC Berkeley, 9 June 2004

%C = rand(7,2);

Np = size(C,1); % number pursuers
Ne = size(C,2); % number evaders

list_ass_i = zeros(Np,1);

done = 0;

while (done==0)
    
    list_not_ass_i = find(list_ass_i==0);   % indeces of not assigned rows
    
    list_ass_j = zeros(Ne,1);               % reset all evaders as unassigned
    list_not_ass_j = find(list_ass_j==0);   % indeces of not assigned columns
    
    Np_na = length(list_not_ass_i);
    Ne_na = length(list_not_ass_j);
    
    Nmin = min(Np_na,Ne_na);
    
    for n=1:Nmin
        list_not_ass_i = find(list_ass_i==0);   % indeces of not assigned rows
        list_not_ass_j = find(list_ass_j==0);   % indeces of not assigned columns
        C_temp = C(list_not_ass_i,list_not_ass_j); %reduced cost matrix to consider only unassigned rows-columns
        
        if size(C_temp,1)<size(C_temp,2)
            C_temp = [ C_temp ; zeros(size(C_temp,2)-size(C_temp,1),size(C_temp,2))];
        else
            C_temp = [ C_temp  zeros(size(C_temp,1),size(C_temp,1)-size(C_temp,2))];
        end
        
        [i_ass_C_temp,j_ass_C_temp] = bottleneck(C_temp);     % bottleneck entry (i,j) in the reduced matrix C_temp
        i_ass_C = list_not_ass_i(i_ass_C_temp);        % bottleneck row entry (i,j) in the original matrix C
        j_ass_C = list_not_ass_j(j_ass_C_temp);        % bottleneck column entry (i,j) in the original matrix C
        list_ass_i(i_ass_C) = j_ass_C;   % assign column to row
        list_ass_j(j_ass_C) = i_ass_C;   % assign row to column  
    end
     list_not_ass_i = find(list_ass_i==0);   % list of unassigned pursuers after previous assignment sweep

    if isempty(list_not_ass_i)  % if still some unassigned pursuers do another assigment sweep
        done =1;
    end
    
    done = 1; %%%%% !!!!!!!! hack to assign only as many pursuers as evaders
end

