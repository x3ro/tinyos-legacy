function rangingTest(node1, node2)
%this function makes two nodes chirp in turn, and turns all other
%nodes off

global TESTBED
addr=node2;

disp(' ')
for i=1:TESTBED.retry
  disp('peg all diagMsgOn(0)')
  peg('all','diagMsgOn',0)
  pause(.5)
end

disp(' ')
for i=1:TESTBED.retry
  disp('peg all initiateSchedule(0)')
  peg all initiateSchedule(0)
  pause(.5)
end

disp(' ')
for i=1:TESTBED.retry
  disp(['peg ' num2str(addr) ' diagMsgOn(1)'])
  eval(['peg ' num2str(addr) ' diagMsgOn(1)'])
  pause(.5)
end

disp(['peg ' num2str(node1) ' CalamariRangeOnce'])
eval(['peg ' num2str(node1) ' CalamariRangeOnce'])



