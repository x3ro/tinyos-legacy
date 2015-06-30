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
 * Revision:		$Revision: 1.4 $
 *
 * $Id: forward.c,v 1.4 2000/08/31 19:06:46 jhill Exp $
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
#include "sys/socket.h"
#include "sys/types.h"
#include "netinet/in.h"


#define REPLY_HANDLER		(1)
#define ROUTE_HANDLER		(6)
#define INIT_HANDLER		(127)
#define REQUEST_HANDLER		(2)
#define REM_REQUEST_HANDLER     (0)

int NumMesg	= 1000;
int Depth	= 1;
char Buf[30] = {REPLY_HANDLER,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26};

volatile int iRepliesIn;
volatile double stop_time;
struct timespec delay, delay1;
int total = 0;

PAMMOTE_ENDPOINT MyEndpoint;
AMMOTE_EP_NAME MyEpName,DestEpName,Hops,R0,R1,R2,R3;

//#define UDP_ADDR "128.32.46.208"
#define UDP_ADDR "127.0.0.1"
//#define UDP_ADDR "169.229.48.201"
#define UDP_PORT 5001


char route_table[256][10];


#define GRAPH_TABLE_DEPTH 25
#define GRAPH_TABLE_ENTRY_SIZE 6
#define GRAPH_TABLE_ENTRIES_PER_LINE 30

char graph_table[GRAPH_TABLE_DEPTH][GRAPH_TABLE_ENTRY_SIZE * GRAPH_TABLE_ENTRIES_PER_LINE];
#define MAX_AGE 50



int s, opt;
int init = 0;


struct sockaddr_in send_addr;

void init_socket(){
	if(init == 1) return;
	init = 1;
	s = socket(AF_INET, SOCK_DGRAM, 0);
    memset(&send_addr, 0, sizeof(send_addr));

 send_addr.sin_family = AF_INET;
    send_addr.sin_addr.s_addr = inet_addr(UDP_ADDR);
    send_addr.sin_port = htons(UDP_PORT);
    opt = 1;
    setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
}

void printRouteTable(){
    int i;
    printf("Route Table......\n");
    printf("_________________\n");
    for(i = 0; i < 256; i ++){
	int j;
	if(route_table[i][0] != 0 && route_table[i][5] < MAX_AGE ){
		route_table[i][5] ++;
		printf("Mote: %x  ", i);
		for(j = 0; j < 5 && route_table[i][j] != 0; j ++){
			printf("%x<-", route_table[i][j]);
		}
		printf("%x<-",i);
		printf("\n");
	}
    }
}



void
ReplyHandler(void *pToken,
	     char *Data)
{

    printf("got reply\n");
    iRepliesIn++;
}
void Gen_graph_table(){
    int i;
    int j, length;
    init_socket();
    for(i = 0; i < GRAPH_TABLE_DEPTH; i ++){
    	graph_table[i][0] = 0;
    	graph_table[i][1] = 0;
    }
    graph_table[0][0] = 1;
    graph_table[0][1] = 5;
    graph_table[0][2] = 0;
    graph_table[0][3] = 3;
    graph_table[0][4] = 0xff;
    graph_table[0][5] = 0;
    graph_table[0][6] = total;
    for(i = 0; i < 256; i ++){
	if(route_table[i][0] != 0  && route_table[i][5] < MAX_AGE ){
		int count;
		int current = i;
		for(j = 0; j < 6 &&  current != 5; j ++) current = route_table[current][0];
		length = j;
		printf("mote %x, length %d\n", i, length);
		count = graph_table[length][0]; 
		//offset was here.
		graph_table[length][0] ++; 
		graph_table[length][count * GRAPH_TABLE_ENTRY_SIZE + 1] = i;
		graph_table[length][count * GRAPH_TABLE_ENTRY_SIZE + 2] = route_table[i][0];
		graph_table[length][count * GRAPH_TABLE_ENTRY_SIZE + 3] = route_table[i][6];
		graph_table[length][count * GRAPH_TABLE_ENTRY_SIZE + 4] = route_table[i][7];
		graph_table[length][count * GRAPH_TABLE_ENTRY_SIZE + 5] = route_table[i][8];
		graph_table[length][count * GRAPH_TABLE_ENTRY_SIZE + 6] = route_table[i][9];
		
	}
  }
    for(i = 5; i > 0; i --){
	for(j = 0; j < graph_table[i][0]; j ++){
		char val = graph_table[i][j *  GRAPH_TABLE_ENTRY_SIZE + 2];
		int k;
		printf("resolving mote %x\n", val);
		for(k = 0; graph_table[i - 1][GRAPH_TABLE_ENTRY_SIZE *k + 1] != val && k < graph_table[i-1][0]; k += 1){}
		if(k > graph_table[i-1][0]) k = 0;
		graph_table[i][j * GRAPH_TABLE_ENTRY_SIZE + 2] = (char)k;
	}
    }

    for(i = 0; i < 5; i ++){
	for(j = 0; j < graph_table[i][0] * 6; j ++){
		printf("%x,", graph_table[i][j+1]);
	}
	printf("\n");
    }
     printf("send returned: %d\n", sendto(s, graph_table, sizeof(graph_table), 0,
               (struct sockaddr *)&send_addr, sizeof(send_addr)));

	nanosleep(&delay, &delay1);


}

void
InitHandler(void *pToken,
	     char *Data)
{;}
void
RouteHandler(void *pToken,
	     char *Data)
{
   int i;
   int length;
   Data -= 7;
   total ++;
   printf("updating: %x\n", Data[0]);
   //for(i = 0; i < 6; i ++) if((Data[i] & 0xc0) != 0x00) return; 
   for(i = 0; i < 8; i ++) printf("%x, ", Data[i]);
   for(i = 1; i < 6 && Data[i] != 0; i ++){;}
   length = i - 1;
   printf("  length: %d \n", length);
   route_table[(int)Data[0] & 0xff][6] = Data[6];
   route_table[(int)Data[0] & 0xff][7] = Data[7];
   route_table[(int)Data[0] & 0xff][8]++;
   route_table[((int)Data[0]) & 0xff][0] = Data[length];
   route_table[((int)Data[0]) & 0xff][5] = 0;
   for(i = length; i > 1; i--){
        route_table[((int)Data[i]) & 0xff][0] = Data[i - 1];
        route_table[((int)Data[i]) & 0xff][5] = 0;
        route_table[((int)Data[i]) & 0xff][9]++;
        printf("updating: %x, %x\n", Data[i], route_table[((int)Data[i]) & 0xff][0]);
   } 
    route_table[((int)Data[i]) & 0xff][5] = 0;
    route_table[5][0] = 0;
    printRouteTable();
    printf("got route\n");
    Gen_graph_table();
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
    double min_rtt;
    
    for(j = 0; j < NumMesg; j++) {
	//printf("%d:\n", j);
    start_time = get_seconds();
//	if(AMMoteRequest(MyEndpoint,DestEpName,4,Buf) != AMMOTE_OK) { 
//	    perror("AMMoteRequest error");
//	    exit(-1);
//	}
	while(iRepliesIn <= j){
	    AMMotePoll(MyEndpoint);
	    nanosleep(&delay, &delay1);
	}
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
	delay.tv_sec = 0;
        delay.tv_nsec = 100;
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

    if(AMMoteSetHandler(MyEndpoint,INIT_HANDLER,InitHandler) != AMMOTE_OK) {
	perror("AMMoteAllocateEndpoint");
	return(1);
    }

    if(AMMoteSetHandler(MyEndpoint,ROUTE_HANDLER,RouteHandler) != AMMOTE_OK) {
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





