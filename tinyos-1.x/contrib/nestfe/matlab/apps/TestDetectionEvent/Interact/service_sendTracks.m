function service_sendTracks( mode , test , debug )


if nargin < 3, debug = []; end
if nargin < 2, test = []; end
if nargin < 1, mode = []; end

if isempty( debug ), debug = false; end
if isempty( test ), test = false; end
if isempty( mode ), mode = 'start'; end


global G_sendTracks

mode = lower( mode );
switch mode


 case 'start'

  if ~isempty( G_sendTracks ) && isfield( G_sendTracks , 'conn' ) && ~isempty( G_sendTracks.conn )
      error('The send tracks service is already started');
  end


  G_sendTracks = [];
  G_sendTracks.debug = debug;
  G_sendTracks.sendTracks = true;
  G_sendTracks.conn = Connection( '' , 7001 , 7000 );
  G_sendTracks.test = test;


  if test

      while true
      %for i = 1:20
	  
	  % generate a random track
	  trackId = round(rand * 2) + 1;
	  trackLen = round(rand * 5) + 3;
	  trackPoints = [ rand(1,trackLen).*300-200 ; rand(1,trackLen).*200-300];
	  track = [ ones(1,trackLen) .* trackId ; trackPoints ];
    
	  % send it
	  sleepTime = rand.*1+2;
	  if G_sendTracks.debug
	      sprintf( 'sleeping for %f seconds' , sleepTime )
	  end
	  pause( sleepTime );
	  if G_sendTracks.debug
              sprintf( 'sending the following track:' )
              track
              G_sendTracks.conn
	  end
	  G_sendTracks.conn = send( G_sendTracks.conn , track );
      end

  end





 case 'stop'

  if isempty( G_sendTracks ) || ~isfield( G_sendTracks , 'conn' ) || isempty(G_sendTracks.conn)
      error('The send tracks service is not started');
  end

  G_sendTracks.sendTracks = false;
  G_sendTracks.conn = close( G_sendTracks.conn );
  G_sendTracks.conn = [];




 otherwise
  error( 'invalid mode' );
end


