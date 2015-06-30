/* -*-Mode: C++; c-file-style: "BSD" -*- */

/*
 * "Copyright (c) 1996-1998 by The Regents of the University of California
 *  All rights reserved."
 *
 * This source code contains unpublished proprietary information 
 * constituting or derived under license from AT&T's UNIX(r) System V.
 * In addition, portions of such source code were derived from Berkeley
 * 4.3 BSD under license from the Regents of the University of California.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: 		U.C. Berkeley Millennium Project
 * File:		ammote_int.h
 * Revision:		$Revision: 1.3 $
 *
 * $Id: ammote_int.h,v 1.3 2000/04/26 01:22:50 philipb Exp $
 */

#ifndef __AMMOTE_INT_H
#define __AMMOTE_INT_H


/* 
 * Internal Constants
 */

#define AMMOTE_TYPE_REQUEST	(0x80)
#define AMMOTE_TYPE_MASK	(0x80)
#define AMMOTE_HANDLERID_MASK	(~AMMOTE_TYPE_MASK)


/* 
 * Internal Data Structures
 */

typedef struct _AMMOTE_HT_ENTRY {
  void (*func)();
} AMMOTE_HT_ENTRY, *PAMMOTE_HT_ENTRY;

typedef struct _AMMOTE_ROUTE {
    unsigned char Hops;
    unsigned char Route[AMMOTE_MAX_HOPS];
} AMMOTE_ROUTE, *PAMMOTE_ROUTE;


typedef struct _AMMOTE_MSG {
    unsigned char R0;
    AMMOTE_HNDLR_ID Handler;
    unsigned char Hops;
    AMMOTE_HNDLR_ID HandlerF;
    unsigned char R1,R2,R3,R4;
    unsigned char Source;
    unsigned char Data[21];
} AMMOTE_MSG, *PAMMOTE_MSG;

struct _AMMOTE_ENDPOINT {
    unsigned int	ReqCredits;
    double		Timeout;
    double		EstRtt;
    PAMMOTE_HT_ENTRY	HandlerTbl;
    PAMMOTE_ROUTE	RouteTbl;
    AMMOTE_EP_NAME	EpName;
    AMMOTE_MSG		OutsReqMsg;
};

struct _AMMOTE_TOKEN {
    PAMMOTE_MSG		pMsg;
    PAMMOTE_ENDPOINT	pEp;
};

#endif /* __AMMOTE_INT_H */

/*
 * $Log: ammote_int.h,v $
 * Revision 1.3  2000/04/26 01:22:50  philipb
 * Added timeout support
 *
 * Revision 1.2  2000/04/25 21:12:58  philipb
 * *** empty log message ***
 *
 *
 */

