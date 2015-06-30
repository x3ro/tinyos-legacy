function definetestbed(varargin)
%definetestbed(varargin)
%
%This function defines groups of ports that connect to regions of the testbed
%Particularly, it defines 4 columns, 8 rows, and West and East sides of the testbed.

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


global testbed

%Column1West
index=1;
for i=1:4
    testbed.column1East{index} = ['testbed:' num2str(i)];   %defines which ports to add
    index=index+1;
end
testbed.column1East{1} = 'COM2';   %defines which ports to add

%Column1East
index=1;
for i=5:8
    testbed.column1West{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end
%Column1
testbed.column1 = union(testbed.column1East, testbed.column1West);   %defines which ports to add


%Column2West
index=1;
for i=9:12
    testbed.column2East{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end
%Column2East
index=1;
for i=13:16
    testbed.column2West{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end
%Column2
testbed.column2 = union(testbed.column2East, testbed.column2West);   %defines which ports to add


%Column3West
index=1;
for i=17:20
    testbed.column3East{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end
%Column3East
index=1;
for i=21:24
    testbed.column3West{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end
%Column3
testbed.column3 = union(testbed.column3East, testbed.column3West);   %defines which ports to add


%Column4West
index=1;
for i=25:28
    testbed.column4East{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end
%Column4East
index=1;
for i=29:32
    testbed.column4West{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end
%Column4
testbed.column4 = union(testbed.column4East, testbed.column4West);   %defines which ports to add


%Row1
index=1;
for i=1:8:25
    testbed.row1{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end

%Row2
index=1;
for i=2:8:26
    testbed.row2{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end

%Row3
index=1;
for i=3:8:27
    testbed.row3{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end

%Row4
index=1;
for i=4:8:28
    testbed.row4{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end

%Row5
index=1;
for i=5:8:29
    testbed.row5{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end

%Row6
index=1;
for i=6:8:30
    testbed.row6{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end

%Row7
index=1;
for i=7:8:31
    testbed.row7{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end

%Row8
index=1;
for i=8:8:32
    testbed.row8{index} = ['testbed:' num2str(3000+i)];   %defines which ports to add
    index=index+1;
end

testbed.westerners = union(testbed.row5, testbed.row6);
testbed.westerners = union(testbed.westerners, testbed.row7);
testbed.westerners = union(testbed.westerners, testbed.row8);

testbed.easterners = union(testbed.row1, testbed.row2);
testbed.easterners = union(testbed.easterners, testbed.row3);
testbed.easterners = union(testbed.easterners, testbed.row4);

testbed.everything = union(testbed.westerners, testbed.easterners);