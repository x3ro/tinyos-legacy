%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pick a far child node and send to this child neighbors
function sendFromAndTo(src, recv, numMessagesToSend)
if ~isstr(src)
    src = num2str(src);
end
if ~isstr(recv)
    recv = num2str(recv);
end
src = ['0x' src]; 
recv = ['0x' recv];
cmd = ['peg ' recv ' rtcrumb(2)'];
eval(cmd);
pause(1);
eval(cmd);    
pause(1);
eval(cmd);   
pause(1);
% cmd = ['peg ' recv ' rtcrumb(3)'];
% eval(cmd); 
% pause(1);
% eval(cmd);
% pause(1);
% eval(cmd);
% pause(1);
cmd = ['peg ' recv ' ststatus']
eval(cmd)
pause(1);
for i = 1:numMessagesToSend
    cmd = ['peg ' src ' rtroute(2,' num2str(mod(i,2)) ')']
    eval(cmd);
    pause(1);
end
cmd = ['peg ' recv ' ststatus']
eval(cmd)
pause(1);
