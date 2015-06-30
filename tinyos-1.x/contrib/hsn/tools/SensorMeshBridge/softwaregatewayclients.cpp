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

#include "softwaregatewayclients.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "connectionmanager.h"
#include "appclients.h"
#include "serialclients.h"
#include "nodeclient.h"
#include "hexutil.h"




SoftwareGatewayCommandClient::SoftwareGatewayCommandClient() :  UART_COMMAND(htons(AM_UARTMSGSENDCOMMAND)),
									RADIO_COMMAND(ntohs(AM_RADIOMSGSENDCOMMAND)){
	memset(&simMsg,0,sizeof(SimMsg));
	simMsg.payloadLength = htons(TOS_MESSAGE_LENGTH);

}

SoftwareGatewayCommandClient::~SoftwareGatewayCommandClient(){}



void SoftwareGatewayCommandClient::sendMsg(unsigned char* data, const short command){
	bufferToSimMsg(data,command);
	send((unsigned char*)&simMsg,TOS_SIM_PACKET_LENGTH);
}


void SoftwareGatewayCommandClient::bufferToSimMsg(unsigned char* buffer, short command){
	simMsg.msgType = command;
	memcpy(&simMsg.msg,buffer,RADIO_PACKET_LENGTH);
}



SoftwareGatewayEventClient::~SoftwareGatewayEventClient(){
	close(fd);
}



SoftwareGatewayEventClient::SoftwareGatewayEventClient() :  UART_EVENT(htons(AM_UARTMSGSENTEVENT)),
									RADIO_EVENT(htons(AM_RADIOMSGSENTEVENT)){


}



void SoftwareGatewayEventClient::performService(ConnectionManager* conn){
	SimMsg* simMsg = (SimMsg*)buffer;

	recieve(buffer,TOS_SIM_HEADER_LENGTH);

	if (recieved != TOS_SIM_HEADER_LENGTH) {
           printf("WARNING: got incorrect sim message header length: %d\n",recieved);
        }

        // Make sure we read the entire payload
        // Note that we may be reading a payload that is not a tos msg!
        unsigned char* currentPos = (unsigned char*) &(simMsg->msg);
        int remainingBytes = ntohs(simMsg->payloadLength);

	while (remainingBytes > 0) {
	   recieve(currentPos, remainingBytes);
           remainingBytes -= recieved;
           currentPos += recieved;
        }

	unsigned char ack = 0;

	this->send(&ack,1);

	if (simMsg->msgType == RADIO_EVENT){

		HexUtil::printHexString("From Sim Radio",(unsigned char *)&(simMsg->msg),TOS_MESSAGE_LENGTH);

		for (int i = 0; i < conn->connections; i++){

			if (NodeClient* node = dynamic_cast<NodeClient*>(conn->deviceList[i])){
				node->send((unsigned char*)&(simMsg->msg),RADIO_PACKET_LENGTH);
				continue;
			}

			if (SerialClient* node = dynamic_cast<SerialClient*>(conn->deviceList[i])){
				node->send((unsigned char*)&(simMsg->msg),RADIO_PACKET_LENGTH);
			}
		}
	}
	else if (simMsg->msgType == UART_EVENT){

		HexUtil::printHexString("From Sim Uart",(unsigned char *)&(simMsg->msg),TOS_MESSAGE_LENGTH);

		for (int i = 0; i < conn->connections; i++){
			
//			if (NodeClient* node = dynamic_cast<NodeClient*>(conn->deviceList[i])){
//				node->send((unsigned char*)&(simMsg->msg),RADIO_PACKET_LENGTH);
//				continue;
//			}

			if (AppClient* node = dynamic_cast<AppClient*>(conn->deviceList[i]))
				node->send((unsigned char*)&(simMsg->msg),RADIO_PACKET_LENGTH);
		}
	}


}

