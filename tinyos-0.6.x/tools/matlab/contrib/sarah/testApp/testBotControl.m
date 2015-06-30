% testBotControl.m
%
% This just provides a test to make sure that the packets are being built
% and sent correctly

CONST_SPEED = 60;
TURN = 20;
FORWARD = 128;

pause on
packetData = buildDataPacket(CONST_SPEED,FORWARD,TURN);
routePackets(1,botPacket(packetData));
packetData

pause(1);

TURN = 35;
packetData = buildDataPacket(CONST_SPEED,FORWARD,TURN);
routePackets(1,botPacket(packetData));
packetData

pause(1);

TURN = 5;
packetData = buildDataPacket(CONST_SPEED,FORWARD,TURN);
routePackets(1,botPacket(packetData));
packetData
