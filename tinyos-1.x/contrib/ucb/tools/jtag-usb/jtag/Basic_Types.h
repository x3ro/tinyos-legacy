// Basic type definitions.

#ifndef _BASIC_TYPES_H_
#define _BASIC_TYPES_H_

// #defines. ------------------------------------------------------------------

#ifndef WIN32
typedef unsigned char BYTE;
typedef char CHAR;
typedef unsigned short WORD;
typedef long LONG;
typedef unsigned long DWORD;
typedef unsigned long * PDWORD;
typedef enum {FALSE, TRUE} BOOL;
typedef unsigned long ULONG;
typedef char * LPTSTR;
#define WINAPI          //replace it for non-windows sources
#else
#include <windows.h>
#endif

typedef LONG STATUS_T;

#define F_BYTE  8
#define F_WORD  16

// Status codes.
enum {
        STATUS_ERROR = -1,
        STATUS_OK    = 0,
};

#endif // _BASIC_TYPES_H_
