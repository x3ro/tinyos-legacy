function [ conn , info ] = recv( conn )

if ~isempty(conn.s)
    info = unpickle( fscanf( conn.s ) );
else
    error( 'The connection is not open' );
end


