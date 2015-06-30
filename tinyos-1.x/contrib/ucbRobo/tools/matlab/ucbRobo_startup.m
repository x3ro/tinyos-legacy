% call this file from your startup.m file
% Look at all areas labeled 'MODIFY' for instructions on what to change


% MODIFY: Change value to path to your tos directory
[flag, value] = system('ncc -print-tosdir'); % in Linux
%value = 'c:/opt/tinyos-1.x/cygwin/opt/tinyos-1.x/tos/';

addpath([value(1:end-1) '/../contrib/ucbRobo/tools/matlab/lib']);
addpath([value(1:end-1) '/../contrib/ucbRobo/tools/matlab/lib/controlBot']);
addpath([value(1:end-1) '/../contrib/ucbRobo/tools/matlab/lib/graphics']);
addpath([value(1:end-1) '/../contrib/ucbRobo/tools/matlab/lib/logging']);
addpath(genpath([value(1:end-1) '/../contrib/ucbRobo/tools/matlab/PEGSim']));

% MODIFY: add applications you are currently concerned with.  Might want to
% use genpath
%addpath([value(1:end-1) '/../contrib/ucbRobo/tools/matlab/apps/MagLightTrail']);
addpath(genpath([value(1:end-1) '/../contrib/ucbRobo/tools/matlab/apps']));



global UCBROBO_DATA_DIR;
global TESTBED_CURRENT_CONN_FILE;
%% POSSIBLE MODIFY: Should you decide to override searching for the
%% environment variable (done below), comment out all the lines under 
%% 'GETTING VALUES FROM ENVIRONMENT VARIABLES' and uncomment the lines
%% here:
% UCBROBO_DATA_DIR = 'you-fill-this';
% addpath(UCBROBO_DATA_DIR);
% disp('using MATLAB variable UCBROBO_DATA_DIR');
% TESTBED_CURRENT_CONN_FILE = 'you-fill-this';
% addpath('directory for TESTBED_CURRENT_CONN_FILE)
% disp('using MATLAB variable TESTBED_CURRENT_CONN_FILE');


%%%%%%%%%% GETTING VALUES FROM ENVIRONMENT VARIABLES %%%%%%%%%%
% MODIFY: Change 'prepath' to path before Cygwin root directory
% If you are in Linux, leave this as ''
prepath = ''; %'c:/opt/tinyos-1.x/cygwin';

%%%%% Stuff below does not need to be modified by the user %%%%%
% Must add to path so matlab can find the connection file in Windows
connFile = getenv('TESTBED_CURRENT_CONN_FILE');
if ~isempty(connFile)
    %below is code to parse and find path, assuming / delimiters.
    arr = strread(connFile,'%s','delimiter','/'); 
    connDir = arr{1};
    for i = 2:(length(arr) - 1)
        connDir = [connDir '/' arr{i}];
    end
    connDir = [prepath connDir];
    addpath(connDir);
    TESTBED_CURRENT_CONN_FILE = [prepath connFile];
else
    disp('Can''t find the environment variable TESTBED_CURRENT_CONN_FILE');
end

% Must add to path so matlab can find the data directory in Windows
dataDir = getenv('UCBROBO_DATA_DIR');
if ~isempty(dataDir)
    dataDir = [prepath dataDir];
    addpath(dataDir);
    UCBROBO_DATA_DIR = dataDir;
else
    disp('Can''t find the environment variable UCBROBO_DATA_DIR');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear flag value arr i connDir connFile dataDir prepath % cleanup workspace
