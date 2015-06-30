function disconnectAll
% Tries to disconnect all open connections

global COMM;

for i=1:length(COMM.connectionName)
    disconnect(COMM.connectionName{i});
end