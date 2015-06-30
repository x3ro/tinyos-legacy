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
 * File:		ammote_rtt.c
 * Revision:		$Revision: 1.6 $
 *
 * $Id: rtt.c,v 1.6 2000/05/03 01:19:07 jhill Exp $
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
#include <timing.h>
#include "ammote.h"


#define REPLY_HANDLER		(1)
#define REQUEST_HANDLER		(2)
#define REM_REQUEST_HANDLER     (0)

int NumMesg	= 1000;
int Depth	= 1;
char Buf[30] = {REPLY_HANDLER,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26};

volatile int iRepliesIn;
volatile double stop_time;

PAMMOTE_ENDPOINT MyEndpoint;
AMMOTE_EP_NAME MyEpName,DestEpName,Hops,R0,R1,R2,R3;


void
ReplyHandler(void *pToken,
	     char *Data)
{

	//printf("got reply\n");
    iRepliesIn++;
}
    extern volatile double start_time;

void
DoSimpleRTT()
{
    int j;
    double delta;
    //double stop_time;
    double sum = 0;
    int sum_count = 0;
    double delta_save;
    double min_rtt;
    
    for(j = 0; j < NumMesg; j++) {
	//printf("%d:\n", j);
    start_time = get_seconds();
	if(AMMoteRequest(MyEndpoint,DestEpName,4,Buf) != AMMOTE_OK) { 
	    perror("AMMoteRequest error");
	    exit(-1);
	}
	while(iRepliesIn <= j)
	    AMMotePoll(MyEndpoint);
    	stop_time = get_seconds();
	if(stop_time - start_time < 2){
		sum += stop_time - start_time;
		sum_count ++;
	} else
		printf("packet lost\n");
    }
    //stop_time = get_seconds();
    
    //delta = (stop_time - start_time) * 1e6;
    delta = sum * 1e6;
    min_rtt = (double) delta / sum_count;

    printf("RTT: %f usec/mesg\n", min_rtt);
    
    fflush(stdout);
    
    return;
}

void
Usage(char *p)
{
    fprintf(stderr, "Usage: %s [-n TotalMsgs] DestinationId Hops R0 R1 R2 R3\n", p);
    fflush(stderr);
}

int
main(int argc,
     char *argv[])
{
    int i;
    /*
     * Parse command line args (note that only node 0 reports errors)
     */
    for(i = 1; i < argc; i++) {
	if(argv[i][0] == '-') {
	    switch((int)argv[i][1]) {
	    case 'n':
		NumMesg = atoi(argv[++i]);
		break;
	    case 'd':
		Depth = atoi(argv[++i]);
		break;
	    default:
		Usage(argv[0]);
		return(1);
	    }
	} 
	else {
	    DestEpName  = atoi(argv[i++]);
	    Hops	= atoi(argv[i++]);
	    R0		= atoi(argv[i++]);
	    R1		= atoi(argv[i++]);
	    R2		= atoi(argv[i++]);
	    R3		= atoi(argv[i++]);
	}
    }

    if(AMMoteInit("/dev/ttyS0") != AMMOTE_OK) {
	perror("AMMoteInit");
	return(1);
    }

    if(AMMoteAllocateEndpoint(&MyEndpoint,&MyEpName) != AMMOTE_OK) {
	perror("AMMoteAllocateEndpoint");
	return(1);
    }

    if(AMMoteSetHandler(MyEndpoint,REPLY_HANDLER,ReplyHandler) != AMMOTE_OK) {
	perror("AMMoteAllocateEndpoint");
	return(1);
    }

    if(AMMoteMapManual(MyEndpoint,DestEpName,Hops,R0,R1,R2,R3) != AMMOTE_OK) {
	perror("AMMoteAllocateEndpoint");
	return(1);
    }
    

    DoSimpleRTT();

    AMMoteFreeEndpoint(MyEndpoint);
    AMMoteTerminate();

    return(0);


}





