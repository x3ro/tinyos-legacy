function printQueryReportMsg_MagLocalAggRpt(address, message, connectionName)
global APPS;

if (isfield(APPS,'MAGDIRECTBOT')) ... % && APPS.MAGDIRECTBOT.rptMsgFlag ...
    % && message.get_type == APPS.MAGDIRECTBOT.QUERYREPORTMSG)
  disp(message)
end