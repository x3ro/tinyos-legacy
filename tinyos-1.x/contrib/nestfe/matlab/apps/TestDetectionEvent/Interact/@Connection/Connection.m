function conn = Connection( remoteHost , localPort , remotePort , precision , callback )
%
%  callback function (which MUST be a function handle) should look like:
%    function callback( newObj )  where newObj is the MATLAB object just received

if nargin < 5, callback = []; end
if nargin < 4, precision = []; end
if nargin < 3, remotePort = []; end
if nargin < 2, localPort = []; end
if nargin < 1, remoteHost = []; end

if isempty( callback ), callback = ''; end
if isempty( precision ), precision = 4; end
if isempty( remoteHost ), remoteHost = '127.0.0.1'; end
if isempty( remotePort ) && isempty( localPort )
    localPort = 5000;
    remotePort = 5001;
elseif isempty( remotePort )
    remotePort = localPort + 1;
elseif isempty( localPort )
    localPort = remotePort - 1;
end


conn = [];
conn.p = precision;
conn.callback = callback;
conn.s = udp( remoteHost , 'RemotePort' , remotePort , 'LocalPort' , localPort );
if ~isempty( conn.callback )
    set( conn.s , 'DatagramReceivedFcn', { @conn_callback , callback } );
end
fopen( conn.s );


% make it a class
conn = class( conn , 'Connection' );
