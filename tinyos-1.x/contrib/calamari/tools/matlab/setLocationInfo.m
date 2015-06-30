function setLocationInfo(nodes, varargin)

global TESTBED

if nargin==0 | isempty(nodes) | strcmp(nodes, 'all')
  nodes=TESTBED.nodeIDs;
end

  
if nargin>1
  TESTBED.anchorNodes=[varargin{:}];
end

for node=nodes
  i= find(TESTBED.nodeIDs==node);
    for j=1:TESTBED.retry
        cmd = ['peg ' num2str(TESTBED.nodeIDs(i)) ' LocationInfo(' num2str(any(find(TESTBED.anchorNodes==TESTBED.nodeIDs(i)))) ','  num2str(ceil(TESTBED.xy(i,1))) ',' num2str(ceil(TESTBED.xy(i,2))) ',' num2str(65534) ',' num2str(65534) ',' num2str(65535) ',' num2str(65535) ',' num2str(65534) ',' num2str(65534) ');'];
        disp(cmd);
        eval(cmd)
        pause(0.25);
    end
end
