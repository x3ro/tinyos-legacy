/** NOTICE: Modified by Mads Bondo Dydensborg, Jan. 2005 */



/************************************************************************************
* The global header file containing typedefs and the like
* The file was created under windows MSVC++
* 
* Author(s):  Kim Schneider, Thomas O. Jensen
*
* (c) Copyright 2004, Freescale, Inc.  All rights reserved.
*
* Freescale Confidential Proprietary
* Digianswer Confidential
*
* No part of this document must be reproduced in any form - including copied,
* transcribed, printed or by any electronic means - without specific written
* permission from Freescale.
*
* Source Safe revision history (Do not edit manually)
*   $Date: 2005/05/23 15:37:09 $
*   $Author: esbenzeuthen $
*   $Revision: 1.2 $
*   $Workfile: DigiType.h $
************************************************************************************/

#ifndef _DIGITYPE_H_
#define _DIGITYPE_H_

// #include "Target.h"
//-----------------------------------------------------------------------------------
//     TYPE DEFINITIONS
//-----------------------------------------------------------------------------------
/* We define these in tos.h... sigh.
typedef signed short int16_t;
typedef unsigned short uint16_t;
typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef signed long int32_t;
typedef unsigned long uint32_t;

typedef signed short intn16_t;
typedef unsigned short uintn16_t;
typedef signed char intn8_t;
typedef unsigned char uintn8_t;
typedef signed long intn32_t;
typedef unsigned long uintn32_t;
*/
typedef int8_t* malloc_ptr_t;
typedef uint8_t bool_t;

//enum{FALSE=0, TRUE=1}; Changed by JK to:
#define TRUE 1
#define FALSE 0

typedef enum {gFlag0, gFlag1} flag_t;
typedef void* handle_t;

#ifndef NULL
#define NULL (void *)(0)
#endif


enum {
  gtest1,
  gtest2,
};

#define getMax(a,b)    (((a) > (b)) ? (a) : (b))
#define getMin(a,b)    (((a) < (b)) ? (a) : (b))

#ifdef ENABLE_ASSERTS

static int gOne_c = 1;

#define ALWAYS_FALSE (gOne_c == 0)
#define ALWAYS_TRUE (gOne_c == 1)

#endif  /* ENABLE_ASSERTS */

#endif  /* _DIGITYPE_H_ */
