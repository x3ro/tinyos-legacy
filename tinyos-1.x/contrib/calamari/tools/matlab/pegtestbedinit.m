%this script will connect me to all the nodes in the intel testbed,
%and set them up to use PEG tools
%
%make sure you run the testbed_start_sf.pl file before starting
%this script

global TOSDIR
addpath([TOSDIR '/../contrib/SystemC/matlab'])
addpath([TOSDIR '/../tools/matlab/contrib/kamin/localizationSimulation/util'])
addpath (genpath ('/home/kamin/ranging'))

global DEBUG
DEBUG=1;

global CONNECT
%CONNECT='packets';
%CONNECT='bytes';
CONNECT='none';

[a,b] = system('echo $TESTBEDPATH');
b=b(1:end-1);
addpath([b '/matlab'])
defineTestbed('../../calamari.cfg')
%defineTestbed('../../test.cfg')

global G_PEG
global TESTBED

initTESTBED;
TESTBED.experimentNumber=1;

fprintf(['Connecting to GenericBase\n']);
peggroup(221)

if(strcmpi(CONNECT,'packets'))
  for i=1:length(TESTBED.nodeIDs)
    fprintf(['Connecting to node ' num2str(TESTBED.nodeIDs(i)) '\n']);
    try
      if isfield(G_PEG,'testbedSource')  & length(G_PEG.testbedSource) >= i & ~isempty(G_PEG.testbedSource(i)) 
	shutdown(G_PEG.testbedSource(i));
      end
      fprintf('peginit: init messenger\n');
      G_PEG.messenger(i)=net.tinyos.matlab.MatlabMessenger;
      G_PEG.messenger(i).displayMessages(1);
      fprintf('peginit: init source\n');
      G_PEG.testbedSource(i) = net.tinyos.packet.BuildSource.makePhoenix(['sf@localhost:' num2str(TESTBED.nodeIDs(i)+9100)],G_PEG.messenger(i) );
      G_PEG.testbedSource(i).setResurrection; %make it try to reconnect instead of killing matlab
      G_PEG.testbedSource(i).start;
    catch
      fprintf('%s\n',lasterr);
      G_PEG.testbedSource(i) = [];
      continue;
    end
    try
      if isfield(G_PEG,'testbedSource')  & length(G_PEG.testbedSource) >= i & ~isempty(G_PEG.testbedSource(i)) 
	shutdown(G_PEG.testbedSource(i));
      end
      fprintf('peginit: init messenger\n');
      G_PEG.messenger(i)=net.tinyos.matlab.MatlabMessenger;
      G_PEG.messenger(i).displayMessages(1);
      fprintf('peginit: init source\n');
      G_PEG.testbedSource(i) = net.tinyos.packet.BuildSource.makePhoenix(['sf@localhost:' num2str(TESTBED.nodeIDs(i)+9100)],G_PEG.messenger(i) );
      G_PEG.testbedSource(i).setResurrection; %make it try to reconnect instead of killing matlab
      G_PEG.testbedSource(i).start;
    catch
      fprintf('%s\n',lasterr);
      G_PEG.testbedSource(i) = [];
      continue;
    end
    try
      fprintf('peginit: init receiver\n');
      G_PEG.testbedReceiver(i) = RawPhoenixReceiver( G_PEG.testbedSource(i), G_PEG.group, 0 );
      G_PEG.testbedReceiver(i).registerListener( G_PEG.listener );
    catch
      fprintf('%s\n',lasterr);
      G_PEG.testbedReceiver(i) = [];
    end
  end
elseif(strcmp(CONNECT,'bytes')) %if we don't want packets connect to the eperbs and get raw bytes
  for i=1:length(TESTBED.nodeIDs)
    fprintf(['Connecting to node ' num2str(TESTBED.nodeIDs(i)) '\n']);
    fprintf('peginit: init source\n');
    try
      G_PEG.testbedSource(i) = net.tinyos.packet.NetworkByteSource(TESTBED.ipAddress(i),10002 );
      G_PEG.testbedSource(i).open;
    catch
      fprintf('%s\n',lasterr);
      G_PEG.testbedSource(i) = [];
    end
    fprintf('peginit: init source_thread\n');
    try
        G_PEG.testbedSource_thread = javaObject( 'NetworkByteSourceThread', G_PEG.testbedSource(i) );
        G_PEG.testbedSource_thread.start;
    catch
        fprintf('%s\n',lasterr);
        G_PEG.testbedSource_thread = [];
    end
  end
end


%pegstart

global CMRI

CMRI.diagMsg = net.tinyos.calamari.DiagMsg;
CMRI.chirpMsg = net.tinyos.calamari.ChirpMsg;
CMRI.transmitModeMsg = net.tinyos.calamari.TransmitModeMsg;
CMRI.timestampMsg = net.tinyos.calamari.TimestampMsg;
CMRI.sensitivityMsg = net.tinyos.calamari.SensitivityMsg;
CMRI.estReportMsg = net.tinyos.calamari.EstReportMsg;
CMRI.transmitCommandMsg = net.tinyos.calamari.TransmitCommandMsg;
