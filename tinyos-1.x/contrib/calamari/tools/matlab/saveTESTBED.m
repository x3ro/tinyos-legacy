function saveTESTBED(filename)
global TESTBED
testbed=TESTBED;
testbed.config=[];
testbed.reportTimer=[];
testbed.runTimer=[];
eval(['save ' filename ' testbed'])
