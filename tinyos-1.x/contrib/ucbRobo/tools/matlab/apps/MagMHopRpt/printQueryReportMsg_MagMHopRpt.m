function printQueryReportMsg_MagMHopRpt(address, message, connectionName)
global APPS;

if (isfield(APPS,'MAGMHOPRPT')) ... % && APPS.MAGMHOPRPT.rptMsgFlag ...
    % && message.get_type == APPS.MAGMHOPRPT.QUERYREPORTMSG)
  disp(message)
end