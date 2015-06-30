%this script will disconnect to all nodes defined in CMRI

global TESTBED

disconnect(TESTBED.address{:});
