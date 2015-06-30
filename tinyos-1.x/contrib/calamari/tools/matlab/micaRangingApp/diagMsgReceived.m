function diagMsgReceived(address, message, connectionName)
%this function prints the value of the diag message.  You need to
%have a different message for each diag message

bytes = message.dataGet;

s = [num2str(getID(connectionName)) ': '];

switch(bytes(2))
 case 1
  disp([s 'Chirp Sent']);
 case 2
  disp([s 'Chirp Send Done Failed']);
 case 3
  disp([s 'Chirp Send Failed'])
 case 4
  disp([s 'Transmitter Mode I2C Send Failed'])
 case 5
  disp([s 'Transmitter Mode I2C Send Done Failed'])
 otherwise
  disp([s 'unknown diag msg'])
end

