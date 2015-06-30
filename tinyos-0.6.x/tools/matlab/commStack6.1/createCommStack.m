
%This function creates the MatlabClock object and tells it to run the comm stack


import net.tinyos.matlab.*;
global COMM

COMM.clock = net.tinyos.matlab.MatlabClock('Comm Stack','runCommStack',1000,bitor(MatlabClock.GUI_ON,MatlabClock.OUTPUT_RESPONSE));