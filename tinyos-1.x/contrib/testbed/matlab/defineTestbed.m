function defineTestbed(filename)
%this function will define the testbed as defined in the
%testbed.cfg file

global TESTBED
TESTBED.configFile = filename;
TESTBED.config = net.tinyos.testbed.TestBedConfig(filename);

for i=1:TESTBED.config.getNumberOfMotes
  mote = TESTBED.config.getMote(i-1);
  TESTBED.id(i) = mote.getId;
  TESTBED.address{i} = ['network@' mote.getAddress.toCharArray' ':10002'];
  TESTBED.x(i) = mote.getX;
  TESTBED.y(i) = mote.getY;
end
