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

#include "broadcastsocket.h"

#include <string.h>
#include <unistd.h>
#include <netdb.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>


#include "nodeclient.h"
#include "exception.h"

extern bool isServer;

BroadcastSocket::BroadcastSocket(){
	sequenceNumber = 0;
	retransmit = true;
}


BroadcastSocket::~BroadcastSocket(){
	
}


void BroadcastSocket::performService(ConnectionManager* conn){

	this->recieve((unsigned char*)&discPacket,sizeof(discPacket));


	if (isServer){
		return;
	}


	if (retransmit && sequenceNumber < ntohl(discPacket.sequenceNumber)){
		sequenceNumber = ntohl(discPacket.sequenceNumber);
		send((unsigned char*)&discPacket,sizeof(discPacket));
	}

	if (conn->getNodeClient() != 0)
		return;


	ClientSocket* node = new NodeClient();
	sequenceNumber = 0;

	try {
		node->connect(discPacket.addr,NODE_SERVER_PORT);
		conn->addIOStream(node);

	}catch(Exception* e){
		printf("Recieved discovery packet from node server and tried to connect:\n");
		e->printErrorMsg();
		delete e;
		delete node;
	}


}





void BroadcastSocket::run(){

	while (!quit){

		try {
			discPacket.sequenceNumber = htonl(++sequenceNumber);
			send((unsigned char*)&discPacket,sizeof(discPacket));
			sleep(DISCOVERY_SEND_INTERVAL);
		} catch (Exception* e){
			e->printErrorMsg();
			return;
		}


	}


}



bool BroadcastSocket::init(const char* localAddr, short port){



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



	int one = 1;
	setsockopt(fd, SOL_SOCKET, SO_BROADCAST,(char *) &one, sizeof(one));

	sin_len = sizeof(clientSockAddr);



	sendSockAddr.sin_family = AF_INET;
	inet_aton("255.255.255.255",&sendSockAddr.sin_addr);
	sendSockAddr.sin_port = htons(port);

	serverSockAddr.sin_family = AF_INET;
	serverSockAddr.sin_addr.s_addr = INADDR_ANY;
	serverSockAddr.sin_port = htons(port);

	if ( bind( fd, (struct sockaddr *) &serverSockAddr, sizeof serverSockAddr ) < 0 ) {
		throw new Exception(this);
		return false;
	}


	return true;

}


void BroadcastSocket::recieve(unsigned char *buffer, int bufferSize){
	if ((recieved = recvfrom(fd, buffer, bufferSize, 0,(sockaddr *)&clientSockAddr,&sin_len)) <= 0)
		throw new Exception(this);
}


void BroadcastSocket::send(unsigned char *data, int length){

	if ((sent = sendto(fd,data,length,0,(sockaddr*)&sendSockAddr, sizeof(sendSockAddr))) <= 0)
		throw new Exception(this);

}




