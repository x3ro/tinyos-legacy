function configMote(reportThresh,winSize,rptItvl,readFireItvl,fadeFireItvl,numFadeItvl,moteID)
% configMote(reportThresh,winSize,rptItvl,readFireItvl,fadeFireItvl,numFadeItvl,moteID)
%
% Allows for command line configuration of motes.

if exist('moteID')
    configMoteD([reportThresh,winSize,rptItvl,readFireItvl,fadeFireItvl,numFadeItvl],moteID)
else
    configMoteD([reportThresh,winSize,rptItvl,readFireItvl,fadeFireItvl,numFadeItvl])
end