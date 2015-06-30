function printMagReportMsg_MagMHopRpt(address, message, connectionName)
% Because MagReportMsgs report very quickly, you may get a steady stream of
% reports if your threshold is set too low.  MAGMHOPRPT.ReportMsgFlag is a
% flag to shut of message reports while you tune the report threshold

global APPS;
    disp(message)

if (isfield(APPS,'MAGMHOPRPT') && APPS.MAGMHOPRPT.rptMsgFlag)
    disp(message)
    % hack to call controller
%    simpBoundaryCtrl(message.get_sourceMoteID);
end