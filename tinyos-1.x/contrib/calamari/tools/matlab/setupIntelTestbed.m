%this script will connect me to all the nodes in the intel testbed,
%and do whatever else I need to do

global TOSDIR
addpath([TOSDIR '/../contrib/calamari/tools/matlab/micaRangingApp'])
addpath([TOSDIR '/../contrib/SystemC/matlab'])

global DEBUG
DEBUG=1;

[a,b] = system('echo $TESTBEDPATH');
b=b(1:end-1);
addpath([b '/matlab'])
defineTestbed([b '/testbed/intel-terrence-testbed.cfg'])
connectTestbed

global CMRI

%define network
%[connectionName  nodeID, xPos, yPos]
%CMRI.network = {{'network@192.168.1.10:10002' 10 [0 0]},
%	   {'network@192.168.1.11:10002' 11 [0 0]},
%	   {'network@192.168.1.12:10002' 12 [0 0]},
%	   {'network@192.168.1.13:10002' 13 [0 0]},
%	   {'network@192.168.1.14:10002' 14 [0 0]},
%	   {'network@192.168.1.15:10002' 15 [0 0]},
%	   {'network@192.168.1.16:10002' 16 [0 0]},
%	   {'network@192.168.1.17:10002' 17 [0 0]},
%	   {'network@192.168.1.18:10002' 18 [0 0]},
%	   {'network@192.168.1.19:10002' 19 [0 0]},
%	   {'network@192.168.1.20:10002' 20 [0 0]},
%	   {'network@192.168.1.21:10002' 21 [0 0]},
%	   {'network@192.168.1.22:10002' 22 [0 0]},
%	   {'network@192.168.1.23:10002' 23 [0 0]},
%	   {'network@192.168.1.24:10002' 24 [0 0]},
%	   {'network@192.168.1.25:10002' 25 [0 0]},
%	   {'network@192.168.1.26:10002' 26 [0 0]},
%	   {'network@192.168.1.27:10002' 27 [0 0]},
%	   {'network@192.168.1.28:10002' 28 [0 0]},
%	   {'network@192.168.1.29:10002' 29 [0 0]}
%	  };

%receive the messages
CMRI.diagMsg = net.tinyos.calamari.DiagMsg;
CMRI.chirpMsg = net.tinyos.calamari.ChirpMsg;
CMRI.transmitModeMsg = net.tinyos.calamari.TransmitModeMsg;
CMRI.timestampMsg = net.tinyos.calamari.TimestampMsg;
CMRI.sensitivityMsg = net.tinyos.calamari.SensitivityMsg;
CMRI.estReportMsg = net.tinyos.calamari.EstReportMsg;
CMRI.transmitCommandMsg = net.tinyos.calamari.TransmitCommandMsg;

receive('diagMsgReceived', CMRI.diagMsg)
receive('chirpMsgReceived', CMRI.chirpMsg)
receive('transmitModeMsgReceived', CMRI.transmitModeMsg)
receive('timestampMsgReceived', CMRI.timestampMsg)
receive('sensitivityMsgReceived', CMRI.sensitivityMsg)
receive('estReportMsgReceived', CMRI.estReportMsg)

%connectTestbed;
