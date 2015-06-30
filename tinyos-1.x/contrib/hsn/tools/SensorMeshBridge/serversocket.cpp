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

#include "serversocket.h"
#include <strings.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <unistd.h>

#include "exception.h"
#include "appclients.h"
#include "nodeclient.h"




ServerSocket::ServerSocket(){}


bool ServerSocket::bindAndListen(short port){
  	sockaddr_in serverSockAddr;

	fd = socket(AF_INET,SOCK_STREAM,0);

	if (fd == SOCKET_ERROR){
		throw new Exception(this);
		return false;
	}

	serverSockAddr.sin_addr.s_addr = INADDR_ANY;
	serverSockAddr.sin_port = htons(port);
	serverSockAddr.sin_family = AF_INET;

	int reuse_opt = 1;

	if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse_opt, sizeof(reuse_opt)) == SOCKET_ERROR) {
		throw new Exception(this);
		return false;
	}


	if (bind(fd,(struct sockaddr*)&serverSockAddr, sizeof(sockaddr_in))  == SOCKET_ERROR) {
		throw new Exception(this);
		return false;
	}


	if (listen(fd,32) == SOCKET_ERROR){
		throw new Exception(this);
		return false;
	}

	return true;
}

ServerSocket::~ServerSocket(){
	close(fd);
}


void ServerSocket::performService(ConnectionManager* conn){
	printf("Accept New Client\n");
	sockaddr_in client;
	int nAddressSize = sizeof(sockaddr_in);
	int newClientSock = accept(fd, (struct sockaddr*)&client, (socklen_t *)&nAddressSize);
	ClientSocket* cSocket = acceptNewClient();
	cSocket->setFileDescriptor(newClientSock);
	conn->addIOStream(cSocket);
}

AsciiHexAppServer::AsciiHexAppServer(){}

AsciiHexAppServer::~AsciiHexAppServer(){}

NodeServer::NodeServer(){}

NodeServer::~NodeServer(){}



ClientSocket* AsciiHexAppServer::acceptNewClient(){
	return new AsciiHexAppClient();
}

ClientSocket* NodeServer::acceptNewClient(){
	return new NodeClient();
}





