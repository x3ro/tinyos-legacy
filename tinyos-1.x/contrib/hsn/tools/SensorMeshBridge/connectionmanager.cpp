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

#include "connectionmanager.h"

#include <stdio.h>
#include "nodeclient.h"
#include "serialclients.h"
#include "exception.h"




ConnectionManager::ConnectionManager(){
	connections = 0;
	nodeClientIterator = 0;
	serialClientIterator = 0;
	softwareGatewayCommandClientIterator = 0;
	badConnections = false;


}

ConnectionManager::~ConnectionManager(){
	for (int i = 0; i < connections; i++)
		delete deviceList[i];
}

void ConnectionManager::addIOStream(ioStream* stream){

	if (connections < MAX_CONNECTIONS){
		list[connections].fd = stream->fd;
		list[connections].events = POLLIN | POLLERR | POLLHUP;
		list[connections].revents = 0;
		deviceList[connections] = stream;
		connections++;
	}
	else {
		printf("Error: Cannot add iostream, max number of connections %i\n",MAX_CONNECTIONS);
	}
}

void ConnectionManager::stop(){
	quit = true;

}

void ConnectionManager::start(){

	quit = false;
	int numOfReads;

	while (!quit) {


		numOfReads = poll(list,connections,POLL_INTERVAL);

		for (int i = 0; i < connections; i++){

			if (list[i].revents & POLLIN) {
				try {
					deviceList[i]->performService(this);
				} catch (Exception* e){
					submitBadConnection(e->getIOStream());
					delete e;
				}

			}

			if ((list[i].revents & POLLERR) || (list[i].revents & POLLHUP)){
				submitBadConnection(deviceList[i]);
			}
		}
		if (badConnections)
			handleBadConnections();


	}

}


void ConnectionManager::submitBadConnection(ioStream* stream){

	stream->printErrorMsg();
	stream->bad = true;
	badConnections = true;
}

void ConnectionManager::handleBadConnections(){


	for (int i = 0; i < connections; i++){
		if (deviceList[i]->bad){
			if (deviceList[i]->attemptReconnect){
				ClientSocket* client = dynamic_cast<ClientSocket*>(deviceList[i]);
				if (client != 0){
					client->reconnect();
					list[i].fd = client->fd;
					client->bad = false;
				}
			}
			else {
				delete deviceList[i];
				connections--;
				deviceList[i] = deviceList[connections];
				list[i] = list[connections];
				if (i >= 0 && i < connections - 1) i--;
			}

		}

	}

	badConnections = false;



}

ClientSocket* ConnectionManager::getNodeClient(){


	if (NodeClient* node = dynamic_cast<NodeClient*>(deviceList[nodeClientIterator]))
		return node;


	for ( nodeClientIterator = 0; nodeClientIterator < connections; nodeClientIterator++){
		if (NodeClient* node = dynamic_cast<NodeClient*>(deviceList[nodeClientIterator]))
			return node;
	}


	nodeClientIterator = 0;
	return 0;

}



ClientSocket* ConnectionManager::getSerialClient(){


	if (SerialClient* node = dynamic_cast<SerialClient*>(deviceList[serialClientIterator]))
		return node;


	for (serialClientIterator = 0; serialClientIterator < connections; serialClientIterator++){
		if (SerialClient* node = dynamic_cast<SerialClient*>(deviceList[serialClientIterator]))
			return node;
	}


	serialClientIterator = 0;
	return 0;

}

SoftwareGatewayCommandClient* ConnectionManager::getSoftwareGatewayCommandClient(){


	if (SoftwareGatewayCommandClient* node = dynamic_cast<SoftwareGatewayCommandClient*>(deviceList[softwareGatewayCommandClientIterator]))
		return node;


	for (softwareGatewayCommandClientIterator = 0; softwareGatewayCommandClientIterator < connections; softwareGatewayCommandClientIterator++){
		if (SoftwareGatewayCommandClient* node = dynamic_cast<SoftwareGatewayCommandClient*>(deviceList[softwareGatewayCommandClientIterator]))
			return node;
	}


	softwareGatewayCommandClientIterator = 0;
	return 0;

}





