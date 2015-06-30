function timestampMsgReceived(address, message, connectionName)

s = [num2str(getID(connectionName)) ': '];

disp([s 'time = ' num2str(message.get_timestamp)])
