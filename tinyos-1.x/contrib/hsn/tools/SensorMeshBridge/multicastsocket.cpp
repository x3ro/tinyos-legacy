/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
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
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:	Mark Yarvis
 *
 */

#include "multicastsocket.h"

#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#include "exception.h"

extern bool isServer;

MulticastSocket::MulticastSocket() {
	retransmit = false;

}


MulticastSocket::~MulticastSocket(){}



bool MulticastSocket::init(const char* localAddr, const char* multicastAddr, short port){

	ip_mreq mreq;

	if (isServer){

		if (inet_aton(localAddr,&discPacket.addr) <= 0){
			throw new Exception(this,"Bad address format");
			return false;
		}
	}


	if ((fd = socket(PF_INET, SOCK_DGRAM, 0)) <= 0) {
		throw new Exception(this);
		return false;
	}

	char one = 1;

	setsockopt(fd, SOL_SOCKET, SO_BROADCAST,&one, sizeof(one));

	sin_len = sizeof(serverSockAddr);

	serverSockAddr.sin_family = AF_INET;
	serverSockAddr.sin_addr.s_addr = htonl(INADDR_ANY);
	serverSockAddr.sin_port = htons(port);

	bzero(&sendSockAddr,sizeof(sendSockAddr));
	sendSockAddr.sin_family = AF_INET;
	sendSockAddr.sin_port = htons(port);
	inet_aton(multicastAddr,&sendSockAddr.sin_addr);

	if (bind(fd,(sockaddr*)&serverSockAddr,sizeof(serverSockAddr)) < 0) {
		throw new Exception(this);
		return false;
	}

	if (inet_aton(multicastAddr,&mreq.imr_multiaddr) == 0) {
		throw new Exception(this,"Bad address format");
		return false;
	}

	mreq.imr_interface.s_addr = INADDR_ANY;
	if (setsockopt(fd,SOL_IP,IP_ADD_MEMBERSHIP,&mreq, sizeof(mreq)) != 0) {
		throw new Exception(this);
		return false;
	}

	return true;

}






