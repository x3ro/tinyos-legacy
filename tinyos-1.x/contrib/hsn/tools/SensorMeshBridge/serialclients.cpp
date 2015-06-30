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

#include "serialclients.h"

#include <stdio.h>
#include <string.h>
#include <fcntl.h>

#include "exception.h"
#include "softwaregatewayclients.h"
#include "connectionmanager.h"

extern bool isServer;


#define BAUDRATE B19200 //the baudrate that the device is talking

SerialClient::SerialClient(){}

SerialClient::~SerialClient(){}

bool SerialClient::recieveMsg(){
	return recieveSize(RADIO_PACKET_LENGTH);
}

void SerialClient::performService(ConnectionManager* conn){

	if (!recieveMsg())
		return;


	HexUtil::printHexString("From Serial",buffer,RADIO_PACKET_LENGTH);

	if (isServer){

		SoftwareGatewayCommandClient* node = conn->getSoftwareGatewayCommandClient();

		if (node != 0){
			node->sendMsg(buffer,node->RADIO_COMMAND);
		}

	} else {
		ClientSocket* node = conn->getNodeClient();
		if (node != 0){
			node->send(buffer,RADIO_PACKET_LENGTH);
		}
	}


}



AsciiHexSerialClient::AsciiHexSerialClient() : SerialClient(){}

AsciiHexSerialClient::~AsciiHexSerialClient(){
	close(fd);
}



void AsciiHexSerialClient::send(unsigned char *buffer, int length){

	unsigned char* output = hexUtil.binToHexAscii(buffer,length);
	ClientSocket::send(output,length);

	//ClientSocket::send(hexUtil.binToHexAscii(buffer,length),length);

}


bool AsciiHexSerialClient::recieveMsg(){
	return hexUtil.recieveMsg(this,buffer);
}




SerialPort::SerialPort(char *commName) : SerialClient(){


	const char * filename = filenameForCommPort(commName);

	struct termios newtio;

	fd = open(filename, O_RDWR|O_NOCTTY);

	if (fd < 0) {
		throw new Exception(this,"Bad serial port file descriptor");
		return;

	}

	tcgetattr(fd, &origtio);

	/* Serial port setting */
	memset(&newtio, 0, sizeof(newtio));
	newtio.c_cflag = BAUDRATE | CS8 | CLOCAL | CREAD;
	newtio.c_iflag = IGNPAR;


	if (BAUDRATE != -1) {
		cfsetospeed(&newtio, (speed_t)BAUDRATE);
		cfsetispeed(&newtio, (speed_t)BAUDRATE);
	}

	/* Raw output_file */
	newtio.c_oflag = 0;
	tcflush(fd, TCIFLUSH);
	tcsetattr(fd, TCSANOW, &newtio);


}


const char* SerialPort::filenameForCommPort(char *commName) {

   for (int i=0; comPorts[i][0]!=0; i++) {
      if (strcmp(commName, comPorts[i][0])==0) {
         return comPorts[i][1];
      }
   }
   return NULL;
}




SerialPort::~SerialPort(){
	close(fd);
}

const char *SerialPort::comPorts[][2] = {{ "COM1", "/dev/ttyS0"},
					{ "COM2", "/dev/ttyS1"},
					{ "COM3", "/dev/ttyS2"},
					{ "COM4", "/dev/ttyS3"},
					{ 0,0}};


const char SerialPort::uart_frame_vals[3] = {0x97, 0x53, 0x71};

void SerialPort::recieve(unsigned char *buffer, int bufferSize){
	if ((recieved = ::read(fd,buffer,bufferSize)) <= 0)
		throw new Exception(this);
}

void SerialPort::send(unsigned char *data, int length){
	if ((sent = ::write(fd, data, length))<= 0)
		throw new Exception(this);
}

