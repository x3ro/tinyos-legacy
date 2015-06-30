function addDataToWatchFreq(h, data)
%addDataToWatchFreq(h, data)
%
%This function takes the handle of a bar plot window and an array of data and sets the data on the plot
%to be a histrogram of the data.
%The array should be a single-row array of discrete values
%

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

%nextVert = [0.5 0; 0.6 0; 0.6 0; 1.4 0; 1.4 0];
watchParams = get(h,'UserData');

tab=tabulate(data);
[r c]=size(tab);

history = zeros(length(watchParams.moteIDs), 2);
history(:,1) = watchParams.moteIDs';
[r2 c2]=size(history);

for i=1:r2
    if history(i,1) <= r
        history(i,2)=tab(history(i,1),2);
    end
end


% for row=1:r
%     if tab(row,2)~=0
%         tabNoZeros(end+1,:)=tab(row,:);
%     end
% end
% 
if watchParams.sortBy~=1
    history = sortRows(history, watchParams.sortBy);
end
[r c]=size(history);

vertices = get(h, 'Vertices');

for i=1:r
    vertices((i-1)*5+3,2)=history(i,2);
    vertices((i-1)*5+4,2)=history(i,2);
end
    
set(h, 'Vertices', vertices)
set(watchParams.figureAxes, 'XTickLabel', history(:,1));

%disp('left addDataToWatch')
