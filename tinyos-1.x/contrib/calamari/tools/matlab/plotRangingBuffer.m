function window=plotRangingBuffer(receiver, transmitter)
%function window=plotRangingBuffer(receiver, transmitter)
%
%plots the values of the window giving estimate from receiver to transmitter

global TESTBED

ind1=find(TESTBED.nodeIDs==receiver);
ind2=find(TESTBED.nodeIDs==transmitter);
window=TESTBED.rangingWindow{ind1,ind2};
if ~isempty(window)
  plot(window)
  title(['ranging estimates received at ' num2str(receiver) ' to ' num2str(transmitter)])
end
