function printRobotCmdMsg(address, message, connectionName)
% Useful for receiving getKp, getKi, getStraight messages.
% These are only for diagnostics, hence no way to turn this off.
global COTSBOTS;
RC = COTSBOTS.RC;

switch(message.get_type) 
    case(RC.GET_STRAIGHT)
        temp = message.get_data;        disp(sprintf('Get Straight: %d', double(temp(1))));
    case(RC.GET_KP)
        temp = message.get_data;        disp(sprintf('Get Kp: %d', double(temp(1))));
    case(RC.GET_KI)
        temp = message.get_data;        disp(sprintf('Get Ki: %d', double(temp(1))));
    otherwise
        disp(message);
end
