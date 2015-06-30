%this script will kill all phoenix sources
global TESTBED
  for i=1:length(TESTBED.nodeIDs)
    fprintf(['Disconnecting from node ' num2str(TESTBED.nodeIDs(i)) '\n']);
    try
      if isfield(G_PEG,'testbedSource') & ~isempty(G_PEG.testbedSource(i))
	shutdown(G_PEG.testbedSource(i));
      end
    catch
      fprintf('%s\n',lasterr);
    end
end
