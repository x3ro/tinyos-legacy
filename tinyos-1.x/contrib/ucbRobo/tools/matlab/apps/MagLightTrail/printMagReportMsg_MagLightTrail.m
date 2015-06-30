function printMagReportMsg_MagLightTrail(address, message, connectionName)
% Because MagReportMsgs report very quickly, you may get a steady stream of
% reports if your threshold is set too low.  MAGLIGHT.ReportMsgFlag is a
% flag to shut of message reports while you tune the report threshold

global APPS;

if (isfield(APPS,'MAGLIGHT') && (APPS.MAGLIGHT.rptMsgFlag))
    disp(message)
end