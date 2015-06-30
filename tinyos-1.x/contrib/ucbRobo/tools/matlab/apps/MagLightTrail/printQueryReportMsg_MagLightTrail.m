function printQueryReportMsg_MagLightTrail(address, message, connectionName)
global APPS;

if ((isfield(APPS,'MAGLIGHT') && APPS.MAGLIGHT.rptMsgFlag && message.type == APPS.MAGLIGHT.QUERYMSG)
  disp(message)
end