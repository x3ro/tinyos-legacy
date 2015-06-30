function f = createField(varargin)
%f = createField(varargin)
%
%this function can take lots of different kinds of parameters and creates
%an array of field structures.
%
%The following are the possible kinds of parameters you can send
%
%f = createField(field, bytes)
%field = field structure
%bytes = string of bytes
%f = new field structure with the data set to the parsed bytes
%
%f = createField('label', size)
%field = string
%bytes = numeric array or number
%f = new field structure with the label =label, size=size, data = zeros
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

f=[];
numParams = length(varargin);
switch numParams
case 1
    p1 = varargin{1};
    if ischar(p1)    
        f.label=p1;
        f.size=1;
        f.data=0;
    end
case 2
    p1 = varargin{1};
    if isstruct(p1)
        if isnumeric(varargin{2})
            bytes = varargin{2};
            if length(bytes) ~= sum(p1.size)
                error('the number of bytes and the byte length of a field must be the same');
            end
            for i=1:length(p1.size)
                num = bytes(1:p1.size(i));
                p1.data(i)=bytes2dec(num);
                bytes = bytes(p1.size(i)+1:end);
            end
            f= p1;
        end
        return
    elseif ischar(p1)
        if isnumeric(varargin{2})
            f.label = p1;
            f.size = varargin{2};
            f.data = zeros(1,length(f.size));
            return
        end
        return
    end
otherwise
	numFields = 0;
	index = 1;
	while (length(varargin)>0) & (index < length(varargin))
        field = createField(varargin{1:index});
        if ~isempty(field)
            numFields = numFields+1;
            f(numFields) = field;
            varargin = {varargin{index+1:end}};
        else
            index = index + 1;
        end
	end
end
