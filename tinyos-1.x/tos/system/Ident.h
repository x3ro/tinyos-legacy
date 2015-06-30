// $Id: Ident.h,v 1.4 2005/06/21 23:27:47 jwhui Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

#ifndef _H_Ident_h
#define _H_Ident_h

enum
{
  IDENT_MAX_PROGRAM_NAME_LENGTH = 16,
};

typedef struct
{
  uint32_t unix_time;  //the unix time that the program was compiled
  uint32_t user_hash;  //a hash of the username and hostname that did the compile
  char program_name[IDENT_MAX_PROGRAM_NAME_LENGTH];  //name of the installed program
} Ident_t;

#ifndef IDENT_PROGRAM_NAME
#define IDENT_PROGRAM_NAME "(none)"
#endif

#ifndef IDENT_USER_HASH
#define IDENT_USER_HASH 0
#endif

#ifndef IDENT_UNIX_TIME
#define IDENT_UNIX_TIME 0
#endif

static const Ident_t G_Ident = {
  unix_time : IDENT_UNIX_TIME,
  user_hash : IDENT_USER_HASH,
  program_name : IDENT_PROGRAM_NAME,
};


#endif//_H_Ident_h

