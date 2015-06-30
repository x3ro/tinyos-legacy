function printMagDebugMsg_MagLocalAggRpt(address, message, connectionName)
% Because MagDebugMsgs report very quickly, you may get a steady stream of
% reports if your threshold is set too low.  MAGDIRECTBOT.rptMsgFlag is a
% flag to shut of message reports while you tune the report threshold

global APPS;
if (isfield(APPS,'MAGDIRECTBOT') && APPS.MAGDIRECTBOT.dbgMsgFlag)
    disp(message);
    disp(sprintf('dMagV[0] : %d ',message.getElement_dMagV(0)));
    disp(sprintf('dMagV[1] : %d ',message.getElement_dMagV(1)));
    disp(sprintf('dMagV[2] : %d ',message.getElement_dMagV(2)));
    disp(sprintf('dMagV[3] : %d ',message.getElement_dMagV(3)));
end