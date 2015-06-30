function p = removeField(p, fieldLabel)
%p = removeField(p, fieldLabel)
%
%this function will remove a field and it's values from the packet
%It will also pad the 'data' section with zeros to maintain the
%length of the packet.
%If there is no 'data' section, it will not pad with zeros
%(i.e. the packet length will change)

%     "Copyright (c) 2000 and The Regents of the University of California.  All rights reserved.
% 
%     Permission to use, copy, modify, and distribute this software and its documentation for any purpose, 
%     without fee, and without written agreement is hereby granted, provided that the above copyright notice 
%     and the following two paragraphs appear in all copies of this software.
%     
%     IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
%     INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
%     EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%     THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
%     THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED 
%     HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
%     PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
%     
%     Authors:  Kamin Whitehouse <kamin@cs.berkeley.edu>
%     Date:     May 10, 2002 

for i=1:length(p.field)                 %for each field
    if strcmpi(p.field(i).label, fieldLabel)        %check if this is the field
        pos = getFieldPosition(p, 'data');
        if pos ~= 0
            dataSize = get(p,'size','data');
            dataSize(end) = dataSize(end)+sum(p.field(i).size);
            p = set(p,'size','data', dataSize); %and change it's size respectively
        end
        p.field = [p.field(1:i-1) p.field(i+1:end)];    %and remove it form the field list
    end
end