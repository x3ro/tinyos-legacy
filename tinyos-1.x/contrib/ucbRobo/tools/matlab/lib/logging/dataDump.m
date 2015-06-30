function dataDump(sessionName,appName)
% dataDump(sessionName,appName)
% Dumps the data structures of all open applications into mat-files for future retrieval
% Tries to stop receiving messages first.
%
% sessionName is a character string appended to the name of the file.  The
% files saved are named 'appName'_sessionName.mat, and dumped in the
% directory in the environment variable 'UCBROBO_DATA_DIR'.
%
% Usage:
%        dataDump   % lazy mode, saves a series of files as appName.mat
%        dataDump('1')   % saves a series of files as appName_1.mat
%        dataDump('1','MAGLIGHT')   % saves a file MAGLIGHT_1.mat

global DATA;
global UCBROBO_DATA_DIR;

if (nargin < 2)
    stopLogging;
else
    stopLogging(appName);
end

if isempty(DATA)
    disp('no data to dump');
    return;
end

if (nargin < 2)
    appNames = fieldnames(DATA);
else
    if isfield(DATA,appName)
        appNames = {appName}
    else
        disp(sprintf('no such application in DATA: %s', appName));
        return;
    end
end

dirName = UCBROBO_DATA_DIR;
if isempty(dirName)
    disp('Saving to current directory since UCBROBO_DATA_DIR does not exist.');
elseif ~(exist(dirName,'dir'))
    disp(['sorry, the directory : ' dirName ' does not exist.']);
    disp(['No data has been outputted.']);
    return;
end

for i = 1:length(appNames)
    if (nargin < 1) %lazy mode
        fileName = [appNames{i} '.mat'];
    else
        fileName = [appNames{i} '_' sessionName '.mat'];
    end
    fileName = [dirName '/' fileName];
    dataStructure = DATA.(appNames{i}); % to make save happy
    save(fileName, 'dataStructure');    %save('-append', fileName, 'dataStructure');
    disp(['Data was saved to file: ' fileName]);
end
