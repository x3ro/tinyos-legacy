function a = set(varargin)
% SET Set properties of the packet and return the updated object
%
%   set(packet, 'field', data)
%
%If you want to set the 'data' field
%or any other field, use the name of that field.
%
%If you want to set the values of all the fields in the packet
%use set 'allData'.   The bytes will automatically be parsed 
%into the correct fields
%
%If you want to set the field structures, use 'field', 
%but the data will not be automatically parsed.
%
%If you want to set the default packet length, use
%DEFAULT_PACKET_LENGTH

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

global DEFAULT_PACKET_LENGTH

a = varargin{1};
prop_name = varargin{2};
if length(varargin) > 3
    fieldLabel = varargin{3};
    val = varargin{4};
else
    fieldLabel = prop_name;
    prop_name = 'data';
    val = varargin{3};
end

if iscellstr(fieldLabel)                          %if the argument is a cell array of strings
    if length(val)==1
        for i = 1:length(fieldLabel)                 %get the value for each element, and accumulate them
            a = set(a, prop_name, fieldLabel{i}, val);
        end
    elseif length(fieldLabel)~=length(val)
        error('Your data and your fields must be the same length')
    else
        for i = 1:length(fieldLabel)                 %get the value for each element, and accumulate them
            a = set(a, prop_name, fieldLabel{i}, val{i});
        end
    end
else                                    %otherwise, if it's just a string
	switch prop_name                    %this switch is for when there are two parameters
	case 'field'                        %return the field structure of the given name
        for i = 1:length(a.field)              
            if strcmpi(a.field(i).label, fieldLabel) 
                a.field(i) = val;                
                return;
            end
        end
        a = addField(a, val);  %this is for when setting the data of a field that doesn't exist yet
	case 'size'                         %return the size of the field of the given name
        f = get(a, 'field', fieldLabel);
        f.size = val;
        a = set(a, 'field', fieldLabel, f);
	case 'label'                         %return the size of the field of the given name
        f = get(a, 'field', fieldLabel);
        f.label = val;
        a = set(a, 'field', fieldLabel, f);
    case 'bytes'
        a = setBytes(a, val);
	case 'data'                         %return the data of the fuield of the given name
        switch fieldLabel               %this switch is for when there is only one parameter
		case 'DEFAULT_PACKET_LENGTH'    %give the default length
            DEFAULT_PACKET_LENGTH = val;
		case 'field'                    %or give ALL field structures
            a.field = val;
        otherwise                       %or give just the data of the field of the given name
            f = get(a, 'field', fieldLabel);
            if isempty(f)
                f = createField(fieldLabel);
            end
            f.data = val;
            a = set(a, 'field', fieldLabel, f);
        end    
	otherwise
        error('I dont understand your parameters')
	end
end