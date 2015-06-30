function ret = PWTestAsync()

global PWStack;
global PWData;

switch PWStack.STATE
 case 1
  if (PWStack.i > length(PWStack.arg.nodes))
    stop (PWStack.TIMER);
    disp('Stopping timer.')
    return
  end
  
  for i = 1:5
    peg('all', 'PWReset');
    pause(1);
  end
  PWData = [];
  peg('all', 'PWRun', ...
      PWStack.arg.duration, PWStack.arg.pktlength, 0, PWStack.arg.nodes(PWStack.i));
  PWStack.STATE = 2;
  PWStack.now = now;
  PWStack.j = 1;
 case 2
  if (now - PWStack.now) * 100000 < PWStack.arg.duration + 2 ; 
    return;
  end
  if PWStack.j <= max(PWStack.arg.nodes) * 2
    if size(PWData,1) < PWStack.j || PWData(PWStack.j,1) ~= PWStack.j 
      peg(PWStack.j, 'PWQuery');
    else
      PWStack.j = PWStack.j + 1;
    end
    return
  end
  savefile=sprintf('Experiment_%d.txt', PWStack.arg.nodes(PWStack.i));
  cd(PWStack.arg.basedir);
  PWData
  save(savefile, 'PWData', '-ASCII');
  PWStack.STATE = 1;
  PWStack.i = PWStack.i + 1;  
end  

% for i=1:numnodes
%    peg all PWReset
%    peg all PQRun(duration, msgsize, 0, i);
%    pause(duration + 1);
%    while didn't get j's response
%       peg i PQQuery
%    save into file