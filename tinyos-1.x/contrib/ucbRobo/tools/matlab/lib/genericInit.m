function genericInit(appStruct, connString)
% Performs common communication connections for applications automatically.
% If connString exists, we make a connection to that one port.
% If connString does not exist, we either:
% 1) try to access the file pointed to by TESTBED_CURRENT_MOTES_FILE, which is one of 
%     the underlying operating system's environment variables
% 2) if that fails, we make a connection to 'sf@localhost:9100', the
%     default
% Then, we call recvAllMsgs(appStruct) to set up the message handlers in
% appStruct
%
% usage: genericInit(MAGLIGHT, 'sf@localhost:9100')
%        genericInit(MAGLIGHT)

global COMM;
global TESTBED_CURRENT_CONN_FILE;

if (nargin < 1)
    usage;
    return;
end

COMM.GROUP_ID = hex2dec('7d'); % use the TOS default group, not Kamin's DD group
% You can change this here, but make sure you're consistent within any one matlab session

disp(sprintf('using the default groupId: %d', COMM.GROUP_ID));
disp('I hope you remembered to startup serial forwarder');

if (nargin == 2) 
    disp(['using the connection: ' connString]);
    connect(connString);
else

    fileName = TESTBED_CURRENT_CONN_FILE;
    openFileFlag = false;
    if ~isempty(fileName) && (exist(fileName) == 2) %2 means is a file
        connStrings = textread(fileName,'%s'); %space delimited file, ONLY conntains connection strings
        if ~ isempty(connStrings)
            openFileFlag = true;
        end
    end

    if openFileFlag
        disp(['using the connections in :' fileName]); 
        for i = 1:length(connStrings)
                connect(connStrings{i});
        end
    else
        connString = 'sf@localhost:9100';
        disp(['using the default connection: ' connString]);
        disp('because the variable or file TESTBED_CURRENT_CONN_FILE does not exist.');
        connect(connString);
    end
end

recvAllMsgs(appStruct);



function usage
disp(['usage: genericInit(MAGLIGHT, ''sf@localhost:9100'')']);
disp(['      genericInit(MAGLIGHT)']);
