function conn_callback( s , event , extCallback )

extCallback( unpickle( fscanf( s ) ) );
