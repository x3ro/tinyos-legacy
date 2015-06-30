function ctrlJoystick(moteID)
% ctrlJoystick(moteID)
% Controls the COTSBOT using a joystick.
%
% NOTES:
% - This uses the 'joy.dll' package by Roberto G. Waissman (2001).
%   The package can be downloaded from Matlab Central.  Use daqregister
%   to register the the 'joy' module.
% - This has been tested to work with the Microsoft Sidewinder Joystick
% - May wish to use the command 'ginput' for control by mouse

global COTSBOTS;

sampleIntvl = 1/COTSBOTS.joystick_refresh;
maxSpeed = COTSBOTS.joystick_maxSpeed/10; % d_i ranges from [-10 10]
pktSendWait = 0.2; % assume 40 pkts/sec, we still have bandwidth left over
RC = COTSBOTS.RC;


% Create the connection to the joystick
% Add 2 channels. One for x and one for y
ai=analoginput('joy',1);
addchannel(ai,[1 2]);

% Set up the display
hFig=figure('DoubleBuffer','on');
hJoy = plot(0,0,'x','MarkerSize',10);
hold on;
axis([-11 11 -11 11]);
COTSBOTS.joystick_quit = false; % Allows user to quit cleanly.
uicontrol(hFig,'Style','pushbutton','String','Quit',...
          'Callback','global COTSBOTS; COTSBOTS.joystick_quit = true;')

while ~COTSBOTS.joystick_quit
     d = getsample(ai);
     set(hJoy,'XData',d(1),'YData',d(2));
     drawnow

    speed=round(maxSpeed*(abs(d(2))));
    turn=round(2*d(1)+20);
    d(2)=-d(2); % for flight joystick, up = forward
    if d(2) > 0
         direction=1;
    else
         direction=0;
    end

    % set direction
    RobotMsg = RobotCmd.RobotCmdMsg;
    RobotMsg.set_type(RC.SET_DIRECTION);
    RobotMsg.set_data([direction 0]);
    send(moteID,RobotMsg);
    RobotMsg
    pause(pktSendWait);

    % set turn
    RobotMsg = RobotCmd.RobotCmdMsg;
    RobotMsg.set_type(RC.SET_TURN);
    RobotMsg.set_data([turn 0]);
    send(moteID,RobotMsg);
    RobotMsg
    pause(pktSendWait);

    % set speed
    RobotMsg = RobotCmd.RobotCmdMsg;
    RobotMsg.set_type(RC.SET_SPEED);
    RobotMsg.set_data([speed 0]);
    send(moteID,RobotMsg);
    RobotMsg
    pause(pktSendWait);

    pause(sampleIntvl - 3*pktSendWait);
end
disp('Exiting ctrlJoystick.');
delete(ai);