function conn = send( conn , info )

if ~isempty( conn.s )
    fprintf( conn.s , pickle(info,conn.p) );
else
    error( 'The connection is not open' );
end
