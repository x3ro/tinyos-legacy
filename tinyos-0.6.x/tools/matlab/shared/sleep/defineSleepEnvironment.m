%defineSleepEnvironment
%
%This file defines the environment needed to interact 
%with the SLEEP component.  
%
%The SLEEP component basically gives you a command
%interface to do set the power mode of the mote
%
%To send packets to a node running SLEEP, first run this file 
%and then run one of the other functions in this directory.
%This will return a packet, which you can then send
%using any type of injection command

global ROOT
addpath([ROOT '/shared/sleep'])

global COMMAND_AM_HANDLER
COMMAND_AM_HANDLER=8;            %8 is the AM handler of COMMAND

global SLEEP_LED_MASK
SLEEP_LED_MASK = 3;

global SLEEP_COMMAND_CODE
SLEEP_COMMAND_CODE = 3;
