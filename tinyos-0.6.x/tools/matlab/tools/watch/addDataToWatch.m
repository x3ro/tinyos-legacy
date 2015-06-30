function addDataToWatch(h, data)
%addDataToWatch(h, data)
%
%This function takes the handle of a plot window and an array of data and adds the data to the plot.
%The array should be a single-row array.  If there are two rows, the second row is interpreted as the x-axis data.
%Otherwise, the data is just plotted against a count of the total number of data points given.
%
%This function should also change the size of the buffers to match the desired size and adjusts the xaxis
%of the graph so that all the data fits on it, etc.

%     "Copyright (c) 2000 and The Regents of the University of California.  All rights reserved.
% 
%     Permission to use, copy, modify, and distribute this software and its documentation for any purpose, without fee, and without written agreement 
%     is hereby granted, provided that the above copyright notice and the following two paragraphs appear in all copies of this software.
%     
%     IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
%     OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%     THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
%     FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
%     PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
%     
%     Authors:  Kamin Whitehouse <kamin@cs.berkeley.edu>
%     Date:     May 10, 2002 

%disp('entered addDataToWatch')
watchParams = get(h,'UserData');
maxLength = watchParams.duration;

x = get(h,'XData');
y = get(h,'YData');

[r c] = size(data);

if watchParams.circularIndex > 0
	if r==2
        index = watchParams.circularIndex;
        for i = 1:c
            x(index) = data(2,i);
            index = mod(index,watchParams.duration)+1;
        end
    end
    index = watchParams.circularIndex;
    for i = 1:c
        y(index) = data(1,i);
        index = mod(index,watchParams.duration)+1;
    end
    watchParams.circularIndex = mod(watchParams.circularIndex+c,watchParams.duration);
    if watchParams.circularIndex==0
        watchParams.circularIndex=watchParams.duration;
    end
    set(watchParams.trace,'XData',mod(watchParams.circularIndex-2,watchParams.duration)+1,'YData',y(mod(watchParams.circularIndex-1,watchParams.duration)+1));
    set(h,'UserData',watchParams);
else
	if r==2
        x = [x data(2,:)];
	else
        newX = ones(1,length(data));
        if ~isempty(x)
            newX = newX * x(end);
        end
        for i = 1:length(data)
            newX(i) = newX(i) + i-1;
        end
        x = [x newX];
	end
	
	y = [y data(1,:)];
	
	if(length(x)-maxLength)>0
        extra = length(x)-maxLength+1;
        x = x(extra:end);
        y = y(extra:end);
	end
end
set(h,'XData',x,'YData',y)
axis tight;
%drawnow

%disp('left addDataToWatch')
