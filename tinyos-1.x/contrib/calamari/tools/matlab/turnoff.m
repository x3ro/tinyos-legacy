global TESTBED
allNodes=10:66;
others=setdiff(allNodes, TESTBED.nodeIDs);
others=union(others, TESTBED.deadNodes);
for i=others
  disp(['peg ' num2str(i) ' reset'])
  peg i 'reset'
  pause(0.75)
end
