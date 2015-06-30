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

#include "clientsocket.h"

#include <arpa/inet.h>
#include <stdio.h>
#include <sys/socket.h>
#include <string.h>
#include <errno.h>
#include <netdb.h>



#include "exception.h"
#include "constants.h"
#include "hexutil.h"


ClientSocket::ClientSocket(){
	pos = 0;
}


ClientSocket::~ClientSocket(){
	close(fd);
}

void ClientSocket::setFileDescriptor(int fd){
	this->fd = fd;
}


bool ClientSocket::connect(char* addr, short port, bool reconnect){
	in_addr localHost;
        bool addressIsName = false;

        for (int i=0; addr[i] != '\0'; i++) {
           if (!(((addr[i] >= '0') && (addr[i] <= '9')) || (addr[i] == '.'))) {
              addressIsName = true;
           }
        }

        if (addressIsName) {
           struct hostent *he;

           printf("Looking up address for name %s\n", addr);
           he = gethostbyname(addr);
           if (he == NULL) {
              throw new Exception(this,"Unknown host");
              return false;
           }
           memcpy(&localHost, he->h_addr, he->h_length);
        } else {

	   if (inet_aton(addr,&localHost) <= 0){
		throw new Exception(this,"Bad address format");
		return false;
	   }
        }
	return connect(localHost,port, reconnect);
}

bool ClientSocket::connect(in_addr addr, short port, bool attempReconnect){
	this->attemptReconnect = attempReconnect;


	bzero(&dest, sizeof(dest));

	dest.sin_family = AF_INET;
	dest.sin_port = htons(port);

	memcpy(&dest.sin_addr.s_addr, &addr, sizeof(addr));
	return reconnect();

}

bool ClientSocket::reconnect(){
	fd = socket(AF_INET,SOCK_STREAM,0);

	if (fd == SOCKET_ERROR){
		throw new Exception(this);
		return false;
	}


	while (::connect(fd, (sockaddr*)&dest, sizeof(dest)) == SOCKET_ERROR) {
		if (!attemptReconnect){
			throw new Exception(this);
			return false;
		}

		printErrorMsg();
		printf("Retry in %i seconds\n",RECONNECT_INTERVAL);
		sleep(RECONNECT_INTERVAL);
	}

	return true;
}


bool ClientSocket::recieveSize(int size){
	recieve(&buffer[pos],size-pos);

	pos += recieved;

	if (pos < size){
		return false;
	}

	pos = 0;

	return true;

}



void ClientSocket::recieve(unsigned char *buffer, int bufferSize){
	if ((recieved = ::recv(fd,buffer,bufferSize,0)) <= 0)
		throw new Exception(this);
}


void ClientSocket::send(unsigned char *data, int length){
	if ((sent = ::send(fd, data, length,0)) <= 0)
		throw new Exception(this);
}

