/*
** Error.h
** Uros Platise, (c) 1997, November
*/

#ifndef __Error
#define __Error
#include <stdio.h>

/* This error class is used to express standard C errors. */
class Error_C { };

/* Out of memory error class informs terminal or upload/download
   tools that it has gone out of valid memory - and that's all.
   Program should not terminate. */
class Error_MemoryRange { };

/* General internal error reporting class that normally force
   uisp to exit after proper destruction of all objects. */
class Error_Device
{
public:
   Error_Device (char *_errMsg, char *_arg=NULL) :
   errMsg(_errMsg), arg(_arg) { }
   void print ()
   {
      if(arg==NULL)
      {
         printf ("%s\n", errMsg);
      }
      else
      {
         printf ("%s: %s\n", errMsg, arg);
      }
   }
private:
   char* errMsg;
   char* arg;
};

#endif
