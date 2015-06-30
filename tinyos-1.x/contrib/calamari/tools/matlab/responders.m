function responders(diag, text)
%thus function stores who sent what kind of diag message

global TESTBED
if strcmpi(diag, 'ranging')
  spaces= find(text.STRING==' ');
  addr = str2num(text.STRING(spaces(end-1)+1:spaces(end)-1));
  TESTBED.received(TESTBED.nodeIDs==addr)=1;
elseif strcmpi(diag, 'chirped')
  spaces= find(text.STRING==' ');
  addr = str2num(text.STRING(spaces(end)+1:end));
  TESTBED.chirped(TESTBED.nodeIDs==addr)=1;
elseif strcmp(diag, 'ident')
  TESTBED.nodeIDsent(TESTBED.nodeIDs==text.routing_origin)=1;
end
