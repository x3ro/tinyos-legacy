function controlBotInit(connString)
% controlBotInit(connString)
% Sets up the communication link to talk to TOSBase which broadcasts to a
% COTSBOT.  This command is idempotent (you can call it multiple times).
%
% connString is something like 'sf@localhost:9100'

global COTSBOTS;
global COMM;

COMM.GROUP_ID = hex2dec('7d'); % use the default group
disp(sprintf('groupID is: %d',COMM.GROUP_ID));
if (nargin < 1)
    COTSBOTS.connString = 'sf@localhost:9100';
    disp('I hope you remembered to startup serial forwarder');
    disp(['Connection String is:   ' COTSBOTS.connString]);
else
    COTSBOTS.connString = connString;
end

% For driving with a joystick
COTSBOTS.joystick_refresh = 10; % Refresh Rate in Hz
COTSBOTS.joystick_maxSpeed = 100; % Arbitrary units
COTSBOTS.joystick_quit = false;

COTSBOTS.driveRaw_minDelay = 0.05; % allow for up to 20 pkts/sec back to back
COTSBOTS.RC = RobotCmd.RC; % so we don't need to reinstantiate
connect(COTSBOTS.connString);
receive('printRobotCmdMsg',RobotCmd.RobotCmdMsg);
