function configureLocalization

%peg 10 IsLastRangingNode(1);
%peg 10 IsLastRangingNode(1);
%peg 10 IsLastRangingNode(1);

%peg 10 IsLastRangingNode;
%peg 10 IsLastRangingNode;
%peg 10 IsLastRangingNode;

peg all MaxAnchorRank(500)
pause(0.25);
peg all MaxAnchorRank(500)
pause(0.25);
peg all MaxAnchorRank(500)
pause(0.25);


peg all RangingParameters(15,1024,5000,20)
pause(0.25);
peg all RangingParameters(15,1024,5000,20)
pause(0.25);
peg all RangingParameters(15,1024,5000,20)
pause(0.25);

peg all UltrasoundFilterParameters(100,300)
pause(0.25);
peg all UltrasoundFilterParameters(100,300)
pause(0.25);
peg all UltrasoundFilterParameters(100,300)
pause(0.25);

% add signal ranging done

%peg all RangingDebug(1)
%pause(0.25);
%peg all RangingDebug(1)
%pause(0.25);
%peg all RangingDebug(1)
%pause(0.25);
peg all PositionDebug(1)
pause(0.25);
peg all PositionDebug(1)
pause(0.25);
peg all PositionDebug(1)
pause(0.25);

peg 10 SignalRangingDone(1);
pause(0.25);
peg 10 SignalRangingDone(1);
pause(0.25);
peg 10 SignalRangingDone(1);
pause(0.25);
