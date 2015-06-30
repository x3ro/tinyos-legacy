

function newLocationInfo
RETRY=3;
dist = 150;
for j=1:RETRY    
    peg 0x200 MyRangingId(2);
    pause(0.25);
    peg('0x200', 'LocationInfo', 1, 0, 0);
    pause(0.25);
    
    peg 0x202 MyRangingId(7);
    pause(0.25);
    peg('0x202', 'LocationInfo', 0, dist, 0);
    pause(0.25);

    peg 0x204 MyRangingId(8);
    pause(0.25);
    peg('0x204', 'LocationInfo', 1, 2 * dist, 0);
    pause(0.25);

    peg 0x220 MyRangingId(3);
    pause(0.25);
    peg('0x220', 'LocationInfo', 0, 0, dist);
    pause(0.25);

    peg 0x222 MyRangingId(6);
    pause(0.25);
    peg('0x222', 'LocationInfo', 0, dist, dist);
    pause(0.25);

    peg 0x224 MyRangingId(9);
    pause(0.25);
    peg('0x224', 'LocationInfo', 0, 2*dist, dist);
    pause(0.25);

    peg 0x240 MyRangingId(4);
    pause(0.25);
    peg('0x240', 'LocationInfo', 1, 0, 2*dist);
    pause(0.25);

    peg 0x242 MyRangingId(5);
    pause(0.25);
    peg('0x242', 'LocationInfo', 0, dist, 2*dist);
    pause(0.25);

    peg 0x244 MyRangingId(10);
    pause(0.25);
    peg('0x244', 'LocationInfo', 1, 2*dist, 2*dist);
    pause(0.25);
    peg('0x244', 'IsLastRangingNode(1)');
    pause(0.25);

    peg all 'RangingDebug(1)';
    pause(0.25);
    peg all 'PositionDebug(1)';
    pause(0.25);
end
