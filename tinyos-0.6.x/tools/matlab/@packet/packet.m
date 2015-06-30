function p = packet(varargin)
%packet is an object that holds arrays of numbers.  Each array must have
%a label and it's size in bytes.  PACKET has several functions
%that allow you to treat these arrays as a byte packet.
%
%   p = PACKET(<fields>) 
%    creates a packet object from with fields (use format of insertField() ) 
%
%This object works closely with the 'fields' structure, which has two variables:
%       fields.label
%       fields.size
%
%The default for <data> is a zero array of size DEFAULT_PACKET_LENGTH
%The default for <fields> is 
%       field(1).label = 'data'
%       field(1).size=[DEFAULT_PACKET_LENGTH]
%
%Packet comes with functions to add/remove fields and change the length.
%There are three ways to add/remove a field:
%     INSERT a field as, e.g. the third field in the packet
%     ADD a field at the beginning of the 'data' section
%     ASSIGN a field a value, in which case it is automatically ADDed
%
%Both methods reduce the 'data' section by the size of the new field.
%If you want the data section to remain the same size, you must 
%explicitly increase its size.  If there is no 'data' section,
%you cannot ADD a field.  However, a data section of size zero does
%allow you to add fields before the position of the 'data' section.
%
%The idea of the 'data' section and these fields are to allow you
%to add repeatedly allow you to add headers and trailers to the 
%packet while indicating where the next layer of headers/data 
%should be held, and a suggestion for how long they should be.
%You can "close" a packet by removing the 'data' field, thereby
%indicating that nobody else should add fields.
%
%Note that the size of a field is the number of bytes that occupies
%in the byte representation of the packet.   Thus, if field.size  = 2
%and the value of the field is 126, it will be converted to [126 00]
%in bytes when injected or displayed. If field.size were 3 it would 
%be converted to [126 00 00] (with little-endian notation).  This is
%convenient because it allows you to represent your packet as real
%numbers instead of as bytes.   However, each field can only hold
%one number, not an array of bytes.  You can however just assign all field
%sizes to be 1 and just use each field as a seperate byte.  
%Or just don't need to use labels at all if you don't want to; just
%treat the packet as a byte array by get(data) set (data), etc.
%
%all values are stored in decimal, but the packet can be displayed in hex.
%
%To DO: add better support and a clearer semantics for adding headers and trailers

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

if (length(varargin) > 0) & isa(varargin{1},'packet')
   p = varargin{1};
   return;
end

p.field.label = 'data';          %the label of the data field
p.field.size = DEFAULT_PACKET_LENGTH;      %the size of the data field
p.field.data = 0;                                 %the data array of this packet, initially just zero
p.time = now;                   %the time the packet was parsed; user datenum(p.time) to change to a number
p=class(p,'packet');                        %make this structure into a class

property_argin = varargin;
if(length(property_argin) > 0)               %if a set of fields were parameters
    p = removeField(p,'data');
    p = insertField(p,varargin{1:end}, 1);       %insert those fields 
end