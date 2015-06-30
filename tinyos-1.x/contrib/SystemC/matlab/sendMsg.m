function sendMsg( port, addr, msg )
%SENDMSG  Send a Msg over a port to a mote address
%
%   msg = sendMsg( port, addr, msg );
%
%   Example: Send a message to localhost:9000 to the broadcast mote id:
%      msg = sendMsg( 9000, 65535, msg );
%
%   Example: Oh, you want to haul off and make the message, too? fine:
%      msg = sendMsg( 9000, 65535, rawMsg( 125, 249, [1 0] ) );

if nargin ~= 3
  error 'wrong number of arguments. usage: sendRawMsg(port,addr,msg)';
end

msg.set_addr( addr );

if isjava(port)
    port.Write(msg.dataGet);
else
    sfs = net.tinyos.util.SerialForwarderStub('localhost',port);
    sfs.Open;
    sfs.Write(msg.dataGet);
    sfs.Close;
end