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
 * File:		ammote.c
 * Revision:		$Revision: 1.10 $
 *
 * $Id: ammote.c,v 1.10 2000/08/31 19:06:46 jhill Exp $
 */


#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <termios.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <errno.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>

#include "ammote.h"
#include "ammote_int.h"
#include "timing.h"

int DevHandle;
volatile double start_time;
int
AMMoteInit(IN char *TtyDev)
{
    struct termios TIOParams;
    int		   Status = AMMOTE_OK;

    if (TtyDev == NULL) {
	Status = AMMOTE_ERROR_PARAMETER;
    }

    DevHandle = open(TtyDev,O_RDWR|O_NOCTTY);
    if (DevHandle == -1) {
	perror("AMMoteMap");
	Status = AMMOTE_ERROR;
	goto done;
    }

    bzero(&TIOParams, sizeof(TIOParams));
    TIOParams.c_cflag = B19200 | CRTSCTS | CS8 | CLOCAL | CREAD;
    TIOParams.c_iflag = IGNPAR | ICRNL;
    
    
    /* Raw output */
    TIOParams.c_oflag = 0;
    
    if (tcflush(DevHandle, TCIFLUSH)) {
	perror("AMMoteInit tcflush");
	Status = AMMOTE_ERROR;
	goto done;
    }
    if (tcsetattr(DevHandle, TCSANOW, &TIOParams)) {
    	perror("AMMoteInit tcsetattr");
	Status = AMMOTE_ERROR;
	goto done;
    }

    printf("AMMoteInit: sizeof(AMMOTE_MSG) = %d\n",sizeof(AMMOTE_MSG));
 done:
    return Status;

}

int
AMMoteTerminate()
{
    int Status = AMMOTE_OK;

    if(close(DevHandle)) {
	perror("AMMoteUnmap close");
	Status = AMMOTE_ERROR;
    }

    DevHandle = -1;

    return Status;
}

int
AMMoteAllocateEndpoint(OUT PAMMOTE_ENDPOINT *ppNewEndpoint,
		       OUT AMMOTE_EP_NAME   *pNewEpName)
{
    PAMMOTE_ENDPOINT	pEp;
    int			Status = AMMOTE_OK;

    pEp = (PAMMOTE_ENDPOINT) malloc(sizeof(AMMOTE_ENDPOINT));
    if (pEp == NULL) {
	perror("AMMoteAllocateEndpoint: Failed to malloc endpoint.\n");
	Status = AMMOTE_ERROR;
	abort();
    }

    pEp->HandlerTbl = (PAMMOTE_HT_ENTRY) malloc(sizeof(AMMOTE_HT_ENTRY) * AMMOTE_MAX_HANDLERS);
    if (pEp->HandlerTbl == NULL) {
	perror("AMMoteAllocateEndpoint: Failed to malloc HT.\n");
	Status = AMMOTE_ERROR;
	abort();
    }

    pEp->RouteTbl = (PAMMOTE_ROUTE) malloc(sizeof(AMMOTE_ROUTE) * 256);
    if (pEp->RouteTbl == NULL) {
	perror("AMMoteAllocateEndpoint: Failed to malloc Route Table.\n");
	Status = AMMOTE_ERROR;
	abort();
    }


    pEp->ReqCredits = AMMOTE_MAX_CREDITS;
    pEp->EstRtt = (double) .5;
    *ppNewEndpoint	= pEp;
    *pNewEpName		= pEp->EpName = 0x7e;

    return Status;
}

int
AMMoteSetHandler(IN PAMMOTE_ENDPOINT pEp,
		 IN AMMOTE_HNDLR_ID  HandlerID,
		 IN void	     (*Handler)())
{

    if((pEp == NULL) || (HandlerID > (AMMOTE_MAX_HANDLERS-1))) {
        return(AMMOTE_ERROR);
    }

    pEp->HandlerTbl[HandlerID].func = Handler;

    return (AMMOTE_OK);
}

int 
AMMoteFreeEndpoint(IN PAMMOTE_ENDPOINT pEp)
{

    if (pEp == NULL) {
	return(AMMOTE_ERROR);
    }

    free(pEp->RouteTbl);
    free(pEp->HandlerTbl);
    free(pEp);

    return (AMMOTE_OK);

}

int
AMMoteMapManual(IN PAMMOTE_ENDPOINT pEp,
	  IN AMMOTE_EP_NAME   RemEpName,
	  IN unsigned char    Hops,
	  IN unsigned char    R0,
	  IN unsigned char    R1,
	  IN unsigned char    R2,
	  IN unsigned char    R3)
{
    int		   Status = AMMOTE_OK;
    
    if ((pEp == NULL) || (RemEpName == 0) || (Hops > AMMOTE_MAX_HOPS)) {
	Status = AMMOTE_ERROR_PARAMETER;
	goto done;
    }
    
    pEp->RouteTbl[RemEpName].Hops = Hops;
    pEp->RouteTbl[RemEpName].Route[0] = R0;
    pEp->RouteTbl[RemEpName].Route[1] = R1;
    pEp->RouteTbl[RemEpName].Route[2] = R2;
    pEp->RouteTbl[RemEpName].Route[3] = R3;
    pEp->RouteTbl[RemEpName].Route[(Hops - 1)] = RemEpName;

 done:
    return Status;

}

int
AMMoteUnmap(IN PAMMOTE_ENDPOINT pEp,
	    IN AMMOTE_EP_NAME   RemEpName)
{
    int Status = AMMOTE_OK;

    if ((pEp == NULL) || (DevHandle == -1)) {
	Status = AMMOTE_ERROR_PARAMETER;
	goto done;
    }


 done:
    
    return Status;

}

static int
intAMMoteSend(IN PAMMOTE_ENDPOINT  pEp) 
{
    int Status = AMMOTE_OK;
    int i;
    printf("sending: ");
    for(i = 0; i < 30; i ++)printf("%x,",((char*)&pEp->OutsReqMsg)[i]);    
    printf("\n");
    if ((write(DevHandle,&pEp->OutsReqMsg,sizeof(AMMOTE_MSG))) < 0) {
	perror("AMMoteSend");
	Status = AMMOTE_ERROR;
	goto done;
    }
    pEp->Timeout = get_seconds() + pEp->EstRtt;

 done:
    return Status;
}


int
AMMotePoll(IN PAMMOTE_ENDPOINT pEp)
{
    AMMOTE_MSG	     IncomingMsg;
    AMMOTE_TOKEN     Token;
    int		     iBytes;
    AMMOTE_HNDLR_ID HandlerID;
    int		     Status = AMMOTE_OK;;

    if ((pEp == NULL) || (DevHandle == -1)) {
	Status = AMMOTE_ERROR_PARAMETER;
	goto done;
    }

    if (ioctl(DevHandle,FIONREAD,&iBytes)) {
	perror("AMMotePoll FATAL");
	Status = AMMOTE_ERROR;
	goto done;
    }

    if (iBytes >= sizeof(AMMOTE_MSG)) {
	iBytes = read(DevHandle,&IncomingMsg,sizeof(AMMOTE_MSG));
	if (iBytes != sizeof(AMMOTE_MSG)) {
	    fprintf(stderr,"AMMotePoll: Read length error.");
	    Status = AMMOTE_ERROR;
	    abort();
	    //goto done;
	}
	
	Token.pMsg = &IncomingMsg;
	Token.pEp = pEp;
	
	HandlerID = IncomingMsg.Handler & AMMOTE_HANDLERID_MASK;
	printf("handler: %d\n", HandlerID);
	if (IncomingMsg.HandlerF & AMMOTE_TYPE_REQUEST) {
	    /* Request Processing */
	   if(pEp->HandlerTbl[HandlerID].func != NULL)
	    ((AMMOTE_HANDLER)(pEp->HandlerTbl[HandlerID].func))(&Token,
								&IncomingMsg.Data[0]);
	    
	    
	}
	else {
	    /* Reply Processing */
	   if(pEp->HandlerTbl[HandlerID].func != NULL)
	    ((AMMOTE_HANDLER)(pEp->HandlerTbl[HandlerID].func))(&Token,
								&IncomingMsg.Data[0]);
	    
	    pEp->ReqCredits++;
	}
	
	
    }
    else if ((pEp->ReqCredits == 0) && ((get_seconds()) > pEp->Timeout)) {
	// Haven't heard a reply in awhile.  Resend request.
	fprintf(stderr,"Timeout!\n");
	start_time = get_seconds();
	intAMMoteSend(pEp);

    }
    

 done:
    return Status;

}

int
AMMoteRequest(IN PAMMOTE_ENDPOINT pEp,
	      IN AMMOTE_EP_NAME   RemEpName,
	      IN AMMOTE_HNDLR_ID  RemHandler,
	      IN char		  *Data)
{
    PAMMOTE_MSG	pMsg;
    int Status = AMMOTE_OK;

    if ((pEp == NULL) || (DevHandle == -1)) {
	Status = AMMOTE_ERROR_PARAMETER;
	goto done;
    }
    
    while (pEp->ReqCredits == 0) {
	AMMotePoll(pEp);
    }
    pMsg = &pEp->OutsReqMsg;
    pEp->ReqCredits -= 1;

    pMsg->HandlerF = RemHandler;
    pMsg->Source = pEp->EpName;
    if ((pMsg->Hops = pEp->RouteTbl[RemEpName].Hops) > 1) {
	pMsg->R0 = pEp->RouteTbl[RemEpName].Route[0];
	pMsg->Handler = 0;
	pMsg->R1 = pEp->RouteTbl[RemEpName].Route[1];
	pMsg->R2 = pEp->RouteTbl[RemEpName].Route[2];
	pMsg->R3 = pEp->RouteTbl[RemEpName].Route[3];
	pMsg->R4 = pEp->RouteTbl[RemEpName].Route[4];
    }
    else {
	pMsg->Hops = 0x11;
	pMsg->R0 = RemEpName;
	pMsg->Handler = pMsg->HandlerF;
    }


    if (Data) {
	memcpy ((void *)&pMsg->Data[0],Data,21);
    }

    Status = intAMMoteSend(pEp);

 done:
    return Status;


}

int
AMMoteReply(IN PAMMOTE_TOKEN	pToken,
	    IN char		*Data)
{
    PAMMOTE_ENDPOINT	pEp;
    AMMOTE_MSG		Msg;
    int Status = AMMOTE_OK;

    if ((pToken == NULL) || (DevHandle == -1)) {
	Status = AMMOTE_ERROR_PARAMETER;
	goto done;
    }

    pEp = pToken->pEp;


 done:
    return Status;

}


/*
 * $Log: ammote.c,v $
 * Revision 1.10  2000/08/31 19:06:46  jhill
 * *** empty log message ***
 *
 * Revision 1.9  2000/05/16 21:47:02  jhill
 * *** empty log message ***
 *
 * Revision 1.8  2000/05/03 01:19:05  jhill
 * *** empty log message ***
 *
 * Revision 1.7  2000/04/29 02:12:55  philipb
 * *** empty log message ***
 *
 * Revision 1.6  2000/04/29 01:46:23  philipb
 * *** empty log message ***
 *
 * Revision 1.5  2000/04/28 22:03:17  philipb
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









