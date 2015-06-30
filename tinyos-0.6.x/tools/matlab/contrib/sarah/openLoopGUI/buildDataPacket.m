function data = buildDataPacket(speed, dir, turn)
% data = buildDataPacket(speed, dir, turn)
% 
% Build the data part of a packet with a single speed/dir/turn command.
%

data = zeros(1,30);
for i=1:15
    data((i-1)*2+1) = speed;
    data(i*2) = dir + turn;
end