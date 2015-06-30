function updateQueryReportMsg_MagMHopRpt(address, message, connectionName)

% Updates the global constants whenever we receive a query report message.

global APPS;

if (isfield(APPS,'MAGMHOPRPT') && APPS.MAGMHOPRPT.rstConstOnRpt ...
    && message.get_type == APPS.MAGMHOPRPT.QUERYREPORTMSG)
    APPS.MAGMHOPRPT.reportThresh = message.get_reportThresh;
    APPS.MAGMHOPRPT.numFadeIntervals = message.get_numFadeIntervals;
    APPS.MAGMHOPRPT.readFireInterval = message.get_readFireInterval;
    APPS.MAGMHOPRPT.fadeFireInterval = message.get_fadeFireInterval;
    APPS.MAGMHOPRPT.windowSize = message.get_windowSize;
    APPS.MAGMHOPRPT.reportInterval = message.get_reportInterval;
end