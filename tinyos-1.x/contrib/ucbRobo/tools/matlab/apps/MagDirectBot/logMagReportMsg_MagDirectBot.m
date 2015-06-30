function logMagReportMsg_MagLocalAggRpt(address, message, connectionName)
% logMagReportMsg_MagLocalAggRpt(address, message, connectionName)
% This function is a MATLAB message handler, and not meant to be called
% directly by the user.
%
% Use MAGDIRECTBOT.logMsgFlag to start/stop logging (through commands
% startLogging, stopLogging)

global APPS;
global DATA;

if (isfield(APPS,'MAGDIRECTBOT') && APPS.MAGDIRECTBOT.logMsgFlag)
    timestamp = clock';
    timestamp = timestamp(4:6);
    data = [message.get_sourceMoteID ; message.get_seqNo ; message.get_dataX ; message.get_dataY ; ...
            message.get_biasX; message.get_biasY ; message.get_posX; message.get_posY ; timestamp];
    DATA.MAGDIRECTBOT.reportMat = [DATA.MAGDIRECTBOT.reportMat data];
end
