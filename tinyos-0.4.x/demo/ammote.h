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
 * File:		ammote.h
 * Revision:		$Revision: 1.1 $
 *
 * $Id: ammote.h,v 1.1 2000/10/19 01:11:21 jhill Exp $
 */

#ifndef __AMMOTE_H
#define __AMMOTE_H

#define IN
#define OUT

#define	AMMOTE_OK		(0)
#define AMMOTE_ERROR		(1)
#define AMMOTE_ERROR_PARAMETER	(2)

#define AMMOTE_MAX_HANDLERS	(128)
#define AMMOTE_MAX_CREDITS	(1)
#define AMMOTE_MAX_HOPS		(5)
/* 
 *  Types
 */
 
typedef struct _AMMOTE_ENDPOINT AMMOTE_ENDPOINT, *PAMMOTE_ENDPOINT;
typedef struct _AMMOTE_TOKEN AMMOTE_TOKEN, *PAMMOTE_TOKEN;

typedef void (*AMMOTE_HANDLER)(PAMMOTE_TOKEN Token, char *Data);

typedef unsigned char AMMOTE_EP_NAME;
typedef unsigned char AMMOTE_HNDLR_ID;

/*
 * Prototypes
 */

int 
AMMoteInit(IN char *TtyDev);

int
AMMoteTerminate();

int
AMMoteAllocateEndpoint(OUT PAMMOTE_ENDPOINT *ppEp,
		       OUT AMMOTE_EP_NAME   *pEpName);

int
AMMoteSetHandler(IN PAMMOTE_ENDPOINT pEp,
		 IN AMMOTE_HNDLR_ID  HandlerID,
		 IN void	     (*Handler)());

int 
AMMoteFreeEndpoint(IN PAMMOTE_ENDPOINT pEp);

int
AMMoteMapManual(IN PAMMOTE_ENDPOINT pEp,
		IN AMMOTE_EP_NAME   RemEpName,
		IN unsigned char    Hops,
		IN unsigned char    R0,
		IN unsigned char    R1,
		IN unsigned char    R2,
		IN unsigned char    R3);

int
AMMoteUnmap(IN PAMMOTE_ENDPOINT pEp,
	    IN AMMOTE_EP_NAME   RemEpName);

int
AMMotePoll(IN PAMMOTE_ENDPOINT pEp);

int
AMMoteRequest(IN PAMMOTE_ENDPOINT pEp,
	      IN AMMOTE_EP_NAME   RemEpName,
	      IN AMMOTE_HNDLR_ID  RemHandler,
	      IN char		  *Data);

int
AMMoteReply(IN PAMMOTE_TOKEN   pToken,
	    IN char		*Data);

#endif /* __AMMOTE_H */

/*
 * $Log: ammote.h,v $
 * Revision 1.1  2000/10/19 01:11:21  jhill
 * *** empty log message ***
 *
 * Revision 1.4  2000/04/28 21:24:13  philipb
 * *** empty log message ***
 *
 * Revision 1.3  2000/04/26 01:22:50  philipb
 * Added timeout support
 *
 * Revision 1.2  2000/04/25 21:12:58  philipb
 * *** empty log message ***
 *
 *
 */

