// This file contains a list of global functions
// that can be called from within web pages.

// Universally available functions

int    atoi(string);
int    intp(any);        // Returns '1' if int, '0' otherwise
int    stringp(any);     
int    pmode(int);       // Change printing modes (0=normal, 1=HTML encode)

int    http_get_argcount();
string http_get_argname(int);
string http_get_argvalue(int);
string http_get_valuebyname(string);


