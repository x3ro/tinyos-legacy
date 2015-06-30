function p = insertField(varargin)
%p = insertField(varargin)
%
%   p = insertField(packet, ( (label, size, position, <value> ) | (field struct, position, <value>) )* )
%
%This function adds a field to a position in the packet.
%The data field is then reduced in size by the size of the new field.
%If the data field is less than the size of the new field,
%the size of the data field remains zero 
%
%There are two types of parameters sets:
%   
%(label, size, position, <value>)
%   label is a string or cell array of strings
%   size is an integer or array of integers
%   position is an integer or array of integers
%   value is an optional argument of a number or array of numbers
%
%(field struct, position, <value>): 
%     field struct is structure or array of structures of the form:
%       field.label  is a string
%       field.size    is an integer
%     position is an integer or array of integers
%     value is an optional argument of a number or array of numbers
%
%these parameter sets can be added in any order or quantity.  The first parameter
%must be a packet object
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

if (length(varargin) <= 0)
    error('must pass packet object parameter')
    return;
elseif isa(varargin{1},'packet')
    p = varargin{1};
    varargin = {varargin{2:end} };
end

while length(varargin)>1
	field = varargin{1};                                            %get the structure and the desired position 
	position = varargin{2}; %note that we expect this to be a single value; could be expanded to be an array of positions
	varargin = {varargin{3:end}};
    
	if length([field.size])~=length([field.data])                       %make sure that the field is valid numerically
        error('Your data does not correspond with the byte sizes')
	end
	
	for i = 1:length(p.field)                                       %make sure there isn't already a field of that name
        for j = 1:length(field)
            if strcmpi(p.field(i).label, field(j).label)
                error('you cannot add two fields of the same name')
            end
        end
	end
	
	p.field = [p.field(1:position-1) field p.field(position:end)]; %add the field
end