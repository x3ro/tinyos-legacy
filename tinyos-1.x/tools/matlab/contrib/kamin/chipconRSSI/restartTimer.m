function restartTimer
global CHIPCON

disp('restarting timer ********************************')
stop(CHIPCON.timer)
pause(5)
start(CHIPCON.timer)