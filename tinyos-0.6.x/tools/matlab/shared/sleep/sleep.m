function p=sleep()
%p=sleep()
%
%This function will create a packet to
%go into SLEEP_MODE
%if your mote is running the COMMAND component
%Adjust the relevant global parameters listed below before calling this function.

global SLEEP_LED_MASK
global SLEEP_COMMAND_CODE

p = commandPacket;
p = set(p, 'ledMask', SLEEP_LED_MASK);
p = set(p, 'commandCode', SLEEP_COMMAND_CODE);
