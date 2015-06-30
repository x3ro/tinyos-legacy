
typedef char** Handle;

//return the pointer this is a handle to
#define deref(h) *(h)

//create a handle from the specified pointer
#define getHandle(p) ((Handle)&(p))

