function varargout = peginit( host, port, group, myaddr )

if nargin < 1; host = 'localhost'; end;
if nargin < 2; port = 9000; end;
if nargin < 3; group = 221; end;
if nargin < 4; myaddr = 1; end;

%%% Set defaults to G_PEG if necessary
if nargout == 0
    global G_PEG;
else
    G_PEG = [];
end
if ~isfield(G_PEG,'host'); G_PEG.host = host; fprintf('host = %s\n',host); end;
if ~isfield(G_PEG,'port'); G_PEG.port = port; fprintf('port = %d\n',port); end;
if ~isfield(G_PEG,'group'); G_PEG.group = group; fprintf('group = %d\n',group); end;
if ~isfield(G_PEG,'myaddr'); G_PEG.myaddr = myaddr; fprintf('myaddr = %d\n',myaddr); end;
if ~isfield(G_PEG,'seq'); G_PEG.seq = 0; end;
G_PEG.seq = G_PEG.seq + 1; if G_PEG.seq > 255; G_PEG.seq = 1; end;
if ~isfield(G_PEG,'source') | isempty(G_PEG.source)
    fprintf('peginit: init source\n');
    try
        G_PEG.source = net.tinyos.util.SerialForwarderStub( G_PEG.host, G_PEG.port );
        G_PEG.source.Open;
    catch
        G_PEG.source = [];
        fprintf('%s\n',lasterr);
    end
end;
if ~isfield(G_PEG,'source_thread') | isempty(G_PEG.source_thread)
    fprintf('peginit: init source_thread\n');
    try
        G_PEG.source_thread = net.tinyos.util.SerialStubThread( G_PEG.source );
        G_PEG.source_thread.start;
    catch
        G_PEG.source_thread = [];
        fprintf('%s\n',lasterr);
    end
end;
if ~isfield(G_PEG,'listener') | isempty(G_PEG.listener)
    fprintf('peginit: init listener\n');
    try
        G_PEG.listener = net.tinyos.matlab.MatlabMessageListener;
        G_PEG.listener.registerMessageListener( 'peglistener' );
    catch
        G_PEG.listener = [];
        fprintf('%s\n',lasterr);
    end
end;
if ~isfield(G_PEG,'receiver') | isempty(G_PEG.receiver)
    fprintf('peginit: init receiver\n');
    try
        G_PEG.receiver = net.tinyos.message.RawReceiver( G_PEG.source, G_PEG.group, 1 );
        G_PEG.receiver.registerListener( G_PEG.listener );
    catch
        G_PEG.receiver = [];
        fprintf('%s\n',lasterr);
    end
end;

if nargout == 1
    varargout{1} = G_PEG;
end
