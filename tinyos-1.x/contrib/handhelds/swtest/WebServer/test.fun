// This file contains a list of functions that
// can be called from within a web page.
// Universal functions are defined in $TOSDIR/contrib/hp/lib/UIP/HTTPinternal.fun

// Local functions
string temp_as_string();               // Return a string of the temperature
string volt_as_string();
int    temp_as_int();
int    volt_as_int();

// Messaging functions
int    msg_count();
string msg_get_text(int);
int    msg_add( string );
int    msg_delete(int);

