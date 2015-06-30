function p = addField(varargin)
%p = addField(varargin)
%
%   p = addField(packet, ( (label, size, <value> ) | (field struct, <value>) )* )
%
%This function adds a field to the beginning of the data field.
%The data field is then reduced in size by the size of the new field.
%If there is no data field, this function does nothing.
%use InsertField to add anywhere, even if there is no 'data' field.
%If the data field is less than the size of the new field,
%the size of the data field remains zero and the new field
%is added before the data field
%
%There are two types of parameters sets:
%
%(label, size, <value>)
%   label is a string or cell array of strings
%   size is a decimal number or array of numbers
%   value is an optional argument of a number or array of numbers
%
%(field struct, <value>): 
%     field struct is structure or array of structures of the form:
%       field.label  is a string
%       field.size    is a decimal number or array of numbers
%     value is an optional argument of a number or array of numbers
%
%these parameter sets can be added in any order or quantity.  The first parameter
%must be a packet object
%
%Note that adding a new field removes data from the 'data' section
%and this data is removed from the end of it.  It is assumed to be zeros
%but if it is not, you should probably save that data somewhere

%TO DO:  create a seperate function that can add new fields but use the existing data
%in the 'data' field as the default data for the new fields.

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

if (length(varargin) <= 0)
    error('must pass packet object parameter')
    return;
elseif isa(varargin{1},'packet')
    p = varargin{1};                %the first parameter is the packet object
    varargin = {varargin{2:end} };
end


while length(varargin) >= 1,
	dataPosition = getFieldPosition(p, 'data');                          %see if there is a 'data' field
	if dataPosition == 0
        error('cannot add when there is no ''data'' field')  %if you want to add a field and there is not 'data' field, use insert field.
        return;
	end
    
    p1 = varargin{1};
    varargin = {varargin{2:end}};
    if isstruct(p1)         %If the first argument is a structure
        p = insertField(p, p1, dataPosition);               %otherwise if there was no value passed, just insert the field
        dataSize = get(p,'size','data');
        dataValues = get(p,'data');
        if all(dataSize==1)
            indices=logical([ones(1, length(dataSize)-sum([p1.size])) zeros(1,sum([p1.size]))]);
            dataSize = dataSize(indices);
            dataValues = dataValues(indices);
        end
%            dataSize(end) = max(0,dataSize(end)-sum([p1.size]));
        p = set(p,'size','data', dataSize); %and change it's size respectively
        p = set(p,'data', dataValues); %and change it's size respectively
    end
end
