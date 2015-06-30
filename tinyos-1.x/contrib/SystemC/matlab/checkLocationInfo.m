function checkLocationInfo(node)
RETRY=1;

for i=1:RETRY
  cmd = ['peg ' num2str(node) ' LocationInfo '];
  eval(cmd);
end
