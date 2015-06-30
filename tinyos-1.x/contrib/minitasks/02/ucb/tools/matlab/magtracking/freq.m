function h = freq (y,values,names)
%FREQ  frequency histogram -- this is my special version of HIST that
%only works with positive integers.  
%
%requires the statistics toolbox 
%
%   FREQ(Y) plots the number of occurences of each of
%   the elements of Y.
%
%   FREQ(Y,VALUES), where VALUES is an array of values ensures that all and
%   only these values will show up on the plot.
%
%   FREQ(Y,VALUES,NAMES), where NAMES is a cell array of the same length as VALUES
%   associates a name on the X axis of the plot for each value.
%
%   H = BAR(...) returns a vector of patch handles.
%
%   See also HIST.

if nargin == 0
    error('Requires one or two input arguments.')
end
if isempty(y)
    newplot
    if nargin==1
        bar(0)
		set(gca, 'XTick', 1); %make sure there are tick values for all numbers
		set(gca, 'XTickLabel', 0); %and change the name of the tick values
    end
    if nargin==2
        bar(zeros(1,length(values)));
		set(gca, 'XTick', 1:length(values)); %make sure there are tick values for all numbers
		set(gca, 'XTickLabel', values); %and change the name of the tick values
    end
    if nargin==3
        bar(zeros(1,length(names)));
		set(gca, 'XTick', 1:length(names)); %make sure there are tick values for all numbers
		set(gca, 'XTickLabel', names); %and change the name of the tick values
    end
    return
end
if min(size(y)) > 1,
   error('Requires Y to be a vector');
end
tmp = y(find(~isnan(y)));
if any(tmp ~= round(tmp)) | any(tmp < 1),
   error('Requires the values of Y to be positive integers.');
end 
maxlevels = max(max(tmp));
[cnts vals] = hist(tmp,(1:maxlevels)); %get the frequency of each element


newcnts=[];
if nargin>1  %if there is a VALUES argument, get the frequency for all and only those values
    for i=1:length(values)
        index=find(values(i)==vals);
        if isempty(index)
            newcnts(end+1) = 0;
        else
            newcnts(end+1) = cnts(find(values(i)==vals));
        end
    end
    counts = newcnts;
	if nargin==2  %and use those values as the x-labels
        names=values;
	else %unless NAMES parameter exists, in which case substitute for the names
        names = names;
	end
else  %if no VALUES parameter was passed, print frequency for all non-zero elements
	counts = cnts(cnts>0);
    names = vals(cnts>0);
end
bar(counts); %show the bar plot
set(gca, 'XTick', 1:length(names)); %make sure there are tick values for all numbers
set(gca, 'XTickLabel', names); %and change the name of the tick values
