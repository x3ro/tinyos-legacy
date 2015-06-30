function inst = readSrec(fname) 
% inst = readSrec(fname)
%
% This function reads an srec file named fname and returns an array where
% each element corresponds to a byte to be downloaded to the
% device. Currently the function expects that the SREC file contains all
% elements in order, starting at address 0, and understands only the S1
% type of entries. 
    

%    "Copyright (c) 2000 and The Regents of the University of California.  All
%    rights reserved. 
%
%    Permission to use, copy, modify, and distribute this software and its 
%    documentation for any purpose, without fee, and without written agreement 
%    is hereby granted, provided that the above copyright notice and the 
%    following two paragraphs appear in all copies of this software. 
%
%    IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
%    FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
%    ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
%    THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
%    DAMAGE.  
%
%    THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
%    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
%    AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
%    IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION
%    TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
%
%    Authors:  Robert Szewczyk <szewczyk@cs.berkeley.edu>
%    Date:     May 28, 2002 
    
    fid = fopen(fname);
    inst = [];
    code = fscanf(fid, '%2c', 1);
    global progID; 
    while(~feof(fid)) ,
	if (code == 'S0') 
	    line = fscanf(fid, '%2x');
	    disp(['SREC: ', sprintf('%c', line(3:length(line)-1))]);
	elseif (code == 'S1')
	    line = fscanf(fid, '%2x');
	    checksum = bitand(sum(line), 255);
	    if (checksum ~= 255) 
		disp(['Checksum error']);
	    else
		    start = line(2)*255+line(3)+1;
		    endi = start + line(1) -4;
		    inst = [inst; line(4:(length(line) - 1))];
	    end
		
	else 
	    disp(['Skipping other code ', code]);
	    fscanf(fid, '%2x');
	end
	code = fscanf(fid, '%2c', 1);
    end
    fclose(fid);
    l = ceil(length(inst) / 16)*16;
    if (l ~= length(inst)) 
	d = l - length(inst)
	inst = [inst; (255*ones(d, 1))];
    end
    progID = docrc(inst);
    return;
    