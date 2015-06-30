function buildLocalization
peggroup(204);
gridInfo;
initNetwork(50);
queryNetworkService;
%disp('Press Enter to Send Location Info');
%pause;
sendOutLocationInfo;
configureLocalization;

for i=2:10 
  checkLocationInfo(i)
  pause(0.25);
end
% initRanging




