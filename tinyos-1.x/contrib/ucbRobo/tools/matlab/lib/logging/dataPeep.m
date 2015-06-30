function dataPeep(appName)
% dataPeep
% Takes a peek at the data structure for appName, particularly to get a
% feel for the size of the data
%
% Usage: dataPeep
%        dataPeep('MAGLIGHT')

global DATA;

if isempty(DATA)
    disp('no data to look at');
    return;
end

if (nargin < 1)
    appNames = fieldnames(DATA);
else
    if isfield(DATA,appName)
        appNames = {appName}
    else
        disp(sprintf('no such application in DATA: %s', appName));
        return;
    end
end

for i = 1:length(appNames)
    disp(['for application :' appNames{i}]);
    DATA.(appNames{i}) % displays the data
end
