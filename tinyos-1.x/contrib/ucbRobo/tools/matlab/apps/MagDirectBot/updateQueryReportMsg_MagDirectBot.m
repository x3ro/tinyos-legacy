function updateQueryReportMsg_MagLocalAggRpt(address, message, connectionName)

% Updates the global constants whenever we receive a query report message.

global APPS;

if (isfield(APPS,'MAGDIRECTBOT') && APPS.MAGDIRECTBOT.rstConstOnRpt ...
    && message.get_type == APPS.MAGDIRECTBOT.QUERYREPORTMSG)
    APPS.MAGDIRECTBOT.reportThresh = message.get_reportThresh;
    APPS.MAGDIRECTBOT.readFireInterval = message.get_readFireInterval;
    APPS.MAGDIRECTBOT.windowSize = message.get_windowSize;
    APPS.MAGDIRECTBOT.timeOut = message.get_timeOut;
    APPS.MAGDIRECTBOT.staleAge = message.get_staleAge;
    APPS.MAGDIRECTBOT.numFadeIntervals = message.get_resetNumFadeIntervals;
    APPS.MAGDIRECTBOT.fadeFireInterval = message.get_fadeFireInterval;
end