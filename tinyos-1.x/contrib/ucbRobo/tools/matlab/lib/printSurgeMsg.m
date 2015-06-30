function printSurgeMsg(address, message, connectionName)
% This file is for debugging purposes.  It dumps out Surge Packets when the
% network is programmed with Surge, WITHOUT doing any parsing for embedded
% packets.  In other words, the packet will be parsed incorrectly.
% Basically, the MIG files do not assume there are any multihop packet
% fields in your TOS_Msg packets, so the offsets for the fields are
% incorrect.

%disp(message.get_data)
