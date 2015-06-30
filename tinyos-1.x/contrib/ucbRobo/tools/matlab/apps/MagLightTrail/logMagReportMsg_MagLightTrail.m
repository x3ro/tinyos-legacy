function logMagReportMsg_MagLightTrail(address, message, connectionName)
% logMagReportMsg(address, message, connectionName)
% This function is a MATLAB message handler, and not meant to be called
% directly by the user.
%
% Because MagReportMsgs report very quickly, you may get a steady stream of
% reports if your threshold is set too low.  MAGLIGHT.ReportMsgFlag is a
% flag to shut of message reports while you tune the report threshold

global APPS;
global DATA;

if (isfield(APPS,'MAGLIGHT') && (APPS.MAGLIGHT.logMsgFlag))
    data = [message.get_sourceMoteID ; message.get_seqNo ; message.get_dataX ; message.get_dataY];
    DATA.MAGLIGHT.reportMat = [DATA.MAGLIGHT.reportMat data];
end
