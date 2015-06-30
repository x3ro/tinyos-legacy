function ChirpMessageReceived(address, message)

global CHIPCON
CHIPCON.numChirpsReceived=CHIPCON.numChirpsReceived+1;
disp(['chirps received: ' num2str(message.get_msgNumber) ' from ' ...
      num2str(message.get_transmitterId) ' at power ' num2str(message.get_rfPower)])
