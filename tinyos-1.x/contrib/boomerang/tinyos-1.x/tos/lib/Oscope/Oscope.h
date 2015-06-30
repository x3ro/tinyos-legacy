//$Id: Oscope.h,v 1.1.1.1 2007/11/05 19:09:15 jpolastre Exp $

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

// @author Nelson Lee
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

#ifndef _H_Oscope_h
#define _H_Oscope_h

#ifndef OSCOPE_MAX_CHANNELS
#define OSCOPE_MAX_CHANNELS 2
#endif

enum
{
  OSCOPE_BUFFER_SIZE = 10,

  AM_OSCOPEMSG = 10,
  AM_OSCOPERESETMSG = 32,
};

typedef struct OscopeMsg
{
  uint16_t sourceMoteID;
  uint16_t lastSampleNumber;
  uint16_t channel;
  uint16_t data[OSCOPE_BUFFER_SIZE];
} OscopeMsg_t;

typedef struct OscopeResetMsg
{
  /* Empty payload! */
} OscopeResetMsg_t;

#endif//_H_Oscope_h

