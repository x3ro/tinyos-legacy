// This file contains a list of functions that
// can be called from within a web page.
// Universal functions are defined in $TOSDIR/contrib/hp/lib/UIP/HTTPinternal.fun

// Messaging functions
int    msg_count();
string msg_get_text(int);
string msg_get_timestamp(int);
int    msg_get_id(int);
int    msg_add( string );
int    msg_delete(int);

