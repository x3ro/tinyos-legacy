global TESTBED
s=sprintf('id                : ');
for i=1:length(TESTBED.nodeIDs)
  s=[s sprintf(' %2d ',TESTBED.nodeIDs(i))];
end
s=[s sprintf('\n')];
disp(s)

s=sprintf('ident             : ');
for i=1:length(TESTBED.nodeIDs)
  s=[s sprintf(' %2d ',TESTBED.identReported(i))];
end
s=[s sprintf('\n')];
disp(s)

s=sprintf('chirped           : ');
for i=1:length(TESTBED.nodeIDs)
  s=[s sprintf(' %2d ',TESTBED.chirpSent(i))];
end
s=[s sprintf('\n')];
disp(s)

s=sprintf('anchorsReported   : ');
for i=1:length(TESTBED.nodeIDs)
  s=[s sprintf(' %2d ',TESTBED.anchorsReported(i))];
end
s=[s sprintf('\n')];
disp(s)

s=sprintf('rangingReported   : ');
for i=1:length(TESTBED.nodeIDs)
  s=[s sprintf(' %2d ',TESTBED.rangingReported(i))];
end
s=[s sprintf('\n')];
disp(s)

s=sprintf('locationReported  : ');
for i=1:length(TESTBED.nodeIDs)
  s=[s sprintf(' %2d ',TESTBED.locationReported(i))];
end
s=[s sprintf('\n')];
disp(s)

s=sprintf('received          : ');
for i=1:length(TESTBED.nodeIDs)
  s=[s sprintf(' %2d ',TESTBED.rangingReceived(i))];
end
s=[s sprintf('\n')];
disp(s)


%for i=1:TESTBED.retry
%  disp('peg all CalamariResetRanging')
%  peg('all', 'CalamariResetRanging')
%  pause(.75)
%end
