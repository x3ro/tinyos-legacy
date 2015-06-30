function id=getID(connectionName)
%this function will get the id of a node given the connection
global TESTBED
id = find(strcmpi(connectionName, TESTBED.address));


