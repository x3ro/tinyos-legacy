function ports=getPortMapping(moteIDs)
%packetPortIndexes=getPortMapping(moteIDs)
%
%This function will retrieve the indexes of the packetPorts 
%of a set of nodes if it is known
%
%if the moteIDs variable is a string 'all' then all
%the indices are returned.

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
global PORT_MAP
global COMM
packetPorts = COMM.packetPorts;

if ischar(moteIDs) & strcmpi(moteIDs,'all')
    ports=packetPorts;
    return;
end
%ports = [];
for i = 1:length(moteIDs)
    for j=1:length(packetPorts)
        pp=get(packetPorts(j),'dataPort');
        if strcmpi(pp.name, PORT_MAP{moteIDs(i)})
            ports(i)=packetPorts(j);
        end
    end
end

if isempty(ports)
    disp('You don''t have a port mapping for some of your moteIDs')
    error('Use ''setPortMapping(moteIDs, packetPorts)'' to set the port mappings before routing.')
end
