function display(p)
% PACKET/DISPLAY Displays the packet to the user
%
%It prints all fields as single variables or arrays
%in decimal notation
%
%If the DISPAY_HEX global variable is set then it prints in
%hexidecimal notation.
%
%It also prints the number of bytes of each field
%next to it's label in parenthesis.
%
%It does not print the values of the 'data' field if they 
% are all zeros
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

global DISPLAY_HEX

if DISPLAY_HEX==1
    displayBytes(p)
    return;
end

if length(p)>1
    for i=1:length(p)
        display(p(i))
    end
end

for i = 1:length(p.field)
	line=sprintf('\t%s(', p.field(i).label);
	line=[line sprintf('%d ', p.field(i).size)];
    line(end)=')';
    line(42)=' ';
    line=[line ':  '];
    line=[line sprintf('%d  ', get(p, p.field(i).label))];
	disp(line)
end
