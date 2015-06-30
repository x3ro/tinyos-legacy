function conn = close( conn )

fclose( conn.s );
delete( conn.s );
conn.s = [];
