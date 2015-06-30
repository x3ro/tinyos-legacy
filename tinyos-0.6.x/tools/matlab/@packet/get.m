function val = get(varargin)
% GET Get properties from the specified object
% and return the value
%
%   data = get(packet, 'field')
%
%If you want to get the 'data' field
%or any other field, use the name of that field.
%
%If you want to get the values of all the fields in the packet
%use get 'allData'
%
%If you want to get the field structures, use 'field'
%
%If you want the default packet length
%use 'DEFAULT_PACKET_LENGTH'

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

global DEFAULT_PACKET_LENGTH

val=[];
a = varargin{1};
prop_name = varargin{2};
if length(varargin) > 2
    fieldLabel = varargin{3};
else
    fieldLabel = prop_name;
    prop_name = 'data';
end

if iscellstr(fieldLabel)                          %if the argument is a cell array of strings
	for i = 1:length(fieldLabel)                 %get the value for each element, and accumulate them
        val{i} = get(a, prop_name, fieldLabel{i});
    end
else                                    %otherwise, if it's just a string
	switch prop_name                    %this switch is for when there are two parameters
	case 'field'                        %return the field structure of the given name
        for i = 1:length(a.field)              
            if strcmpi(a.field(i).label, fieldLabel) 
                val = a.field(i);                
                return;
            end
        end
        return;
	case 'size'                         %return the size of the field of the given name
        f = get(a, 'field', fieldLabel);
        val = f.size;
	case 'data'                         %return the data of the fuield of the given name
        switch fieldLabel               %this switch is for when there is only one parameter
		case 'DEFAULT_PACKET_LENGTH'    %give the default length
            val = DEFAULT_PACKET_LENGTH;
		case 'field'                    %or give ALL field structures
            val = a.field;
        case 'size'                     %or give TOTAL size
            val = sum([a.field.size]);
		case 'time'                         %return the size of the field of the given name
            val = a.time;
        case 'allData'                     %or give ALL data in an array
            val = [a.field.data];
        otherwise                       %or give just the data of the field of the given name
            f = get(a, 'field', fieldLabel);
            if ~isempty(f)
                val = f.data;
            elseif strcmpi(fieldLabel,'packetLength') | strcmpi(fieldLabel,'length') %if the user asked for the packetLength, but 'packetLength' is not a field, just return the headers' size
                val = sum([a.field.size]);
            else
                val=f;
            end
        end    
	otherwise
        error('I dont understand your parameters')
	end
end