
/* Some useful defines for use in TOS programs */
#ifndef __UTIL_H__
#define __UTIL_H__

typedef char bool;
typedef char byte;
typedef char (*func_ptr)();
typedef char int1;
typedef short int2;
typedef long int4;
typedef char *String;

#define TRUE 1
#define FALSE 0

// #define NULL 0x00

//error codes for use in TOS functions
#define TOS_Success 1
#define TOS_Failure 0

typedef char *CharPointer;
#endif 
