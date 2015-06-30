function dataPorts = addDataPorts(portNames)
%dataPorts = addDataPorts(portNames)
%
%This function takes a cell array of strings and opens
%ports of those names.  It then adds then to the commStack

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

global COMM

% if isfield(COMM, 'dataPorts')
%     dataPortNames = get(COMM.dataPorts,'name');
% else
%     dataPortNames={};
% end
% if ~iscell(dataPortNames)
%     serialPortNames = {serialPortNames};
% end

dataPorts = openSerialPort(portNames);

% for name=1:length(serialPortNames)
%     if findstr(serialPortNames{name}, upper(portNames{i}))
%         s = serialPorts(name);
%         return
%     end
% end

if ~isfield(COMM, 'dataPorts')
    COMM.dataPorts = dataPorts;    %open those ports
else
    COMM.dataPorts = [COMM.dataPorts dataPorts];
end
