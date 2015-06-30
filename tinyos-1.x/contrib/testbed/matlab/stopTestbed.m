function stopTestbed(varargin)
%this script will disconnect the given nodes in TESTBED

global TESTBED
if nargin==0
  stopComm(TESTBED.address{:})
end

for i=1:nargin
  index = find(varargin{i} == TESTBED.id)
  if ~isempty(index)
    stopComm(TESTBED.address{index});
  end
end

