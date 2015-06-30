function msg = rawMsg( group, am, data_bytes )
%RAWMSG  Create a TOSMsg with the given Group, AM, and data_bytes as body
%
%   msg = rawMsg( group, am, data_bytes );
%
%   Example: Create message to turn on motes:
%      msg = rawMsg( 125, 249, [1 0] );
%
%   Example: Oh, you want to haul off and send it, do you? fine:
%      msg = sendMsg( 9000, 65535, rawMsg( 125, 249, [1 0] ) );

if nargin ~= 3
  error 'wrong number of arguments. usage: rawMsg(group,am,bytes)';
end

data_bytes = min( data_bytes, 255 );
data_bytes(data_bytes>127) = data_bytes(data_bytes>127) - 256;

msg = net.tinyos.message.RawTOSMsg(36);

if ~isempty(am)
    msg.amTypeSet( am );
    msg.set_type( am );
end

if ~isempty(group)
  msg.set_group( group );
end

if ~isempty(data_bytes)
    msg.set_data( int8(data_bytes) );
end

msg.set_length( length(data_bytes) );

