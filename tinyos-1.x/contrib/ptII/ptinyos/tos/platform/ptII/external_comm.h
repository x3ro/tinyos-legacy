// $Id: external_comm.h,v 1.4 2006/07/13 07:03:14 celaine Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#ifndef EXTERNAL_COMM_H_INCLUDED
#define EXTERNAL_COMM_H_INCLUDED

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <errno.h>
//#include <pthread.h>

// celaine
//#define COMMAND_PORT 10584
//#define EVENT_PORT 10585
#define MAX_CLIENT_CONNECTIONS 4

norace static int socketsInitialized = 0;
void initializeSockets();
// Viptos: replacing C socket operations with Java sockets.
//int readTossimCommand(int clifd, int clidx);
int readTossimCommand(void *socketChannel, int clidx);
void buildTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data,
                      unsigned char **msgp, int *lenp);
void sendTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data);

// Viptos: replacing C socket operations with Java sockets.
//int writeTossimEvent(void *data, int datalen, int clifd);
int writeTossimEvent(void *data, int datalen, void* socketChannel);

int notifyTaskPosted(char* task);
int notifyEventSignaled(char* event);
int notifyCommandCalled(char* command);
char* currentTime();
int printTime(char* buf, int len);
int printOtherTime(char* buf, int len, long long int ftime);

// Viptos
extern void ptII_startThreads();
extern int ptII_joinThreads();

#endif
