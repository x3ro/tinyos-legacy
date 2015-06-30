function printMagLeaderReportMsg_MagLocalAggRpt(address, message, connectionName)
% Because MagReportMsgs report very quickly, you may get a steady stream of
% reports if your threshold is set too low.  MAGDIRECTBOT.ReportMsgFlag is a
% flag to shut of message reports while you tune the report threshold

global APPS;
if (isfield(APPS,'MAGDIRECTBOT'))% && APPS.MAGDIRECTBOT.rptMsgFlag)
    disp(message)
end