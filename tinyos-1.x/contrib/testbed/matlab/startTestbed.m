function startTestbed(varargin)
%this script will disconnect the given nodes in CMRI

global TESTBED
if nargin==0
  startComm(TESTBED.address{:})
end

for i=1:nargin
  index = find(varargin{i} == TESTBED.id)
  if ~isempty(index)
    startComm(TESTBED.address{index});
  end
end

