function logMagReportMsg_MagMHopRpt(address, message, connectionName)
% logMagReportMsg_MagMHopRpt(address, message, connectionName)
% This function is a MATLAB message handler, and not meant to be called
% directly by the user.
%
% Use MAGMHOPRPT.logMsgFlag to start/stop logging (through commands
% startLogging, stopLogging)

global APPS;
global DATA;

if (isfield(APPS,'MAGMHOPRPT') && APPS.MAGMHOPRPT.logMsgFlag)
    timestamp = clock';
    timestamp = timestamp(4:6);
    data = [message.get_sourceMoteID ; message.get_seqNo ; message.get_dataX ; message.get_dataY ; ...
            message.get_dMagSum ; message.get_magReadCount ; timestamp];
    DATA.MAGMHOPRPT.reportMat = [DATA.MAGMHOPRPT.reportMat data];
end
