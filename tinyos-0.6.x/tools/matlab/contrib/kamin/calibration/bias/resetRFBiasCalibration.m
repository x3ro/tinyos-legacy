function resetRFBiasCalibration(varargin)
%resetRFBiasCalibration(<moteIDs>
%
%this function starts calibration all over again.
%If you don't pass any moteIDs it resets all calibrated motes

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

global RF_CALIBRATION

if length(varargin) > 0
    moteIDs = varargin{1};
else
    moteIDs = RF_CALIBRATION.moteIDs;
end

if length(varargin)==0 | (ischar(moteIDs) & strcmpi(moteIDs,'all'))
	RF_CALIBRATION.active = [];
	
	RF_CALIBRATION.watchedMoteID = [];
	
	RF_CALIBRATION.ambientRF = {};
	
	RF_CALIBRATION.bias = {};
	
	RF_CALIBRATION.std= {};
else
    RF_CALIBRATION.active(moteIDs) = 0;
	
	RF_CALIBRATION.watchedMoteID = [];
	
	RF_CALIBRATION.ambientRF{moteIDs} = [];
	
	RF_CALIBRATION.bias{moteIDs} = [];
	
	RF_CALIBRATION.std{moteIDs}= [];
end