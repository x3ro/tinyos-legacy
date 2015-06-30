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

#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include "softwaregatewayclients.h"
#include "nodeclient.h"
#include "multicastsocket.h"
#include "broadcastsocket.h"
#include "serialclients.h"
#include "connectionmanager.h"
#include "serversocket.h"
#include "exception.h"


bool isServer;
bool isQuiet;
bool isSimBridge;
static ConnectionManager conn;
static bool useBeacon;
static bool useBroad;
static bool isSerialSock;
static char* serialPort = "NONE";
static char* gateIP = "127.0.0.1";
static char* serverIP = "127.0.0.1";
static int appServerPort = APP_SERVER_PORT;

static bool getUsage(bool& isServer, int argc, char **argv){
	isQuiet = false;
	useBeacon = false;
	isSerialSock = false;
	useBroad = true;

	int i = 1;

	if (argc < 2)
		return false;

	if (strcmp(argv[i],"-c" ) == 0){
		isServer = false;
		isSimBridge = false;
		i++;
	}

	else if (strcmp(argv[i],"-s" ) == 0){

		isServer = true;
		isSimBridge = false;
		i++;

	}
	else if (strcmp(argv[i],"-m") == 0){
		isServer = false;
		isSimBridge = true;
		i++;
	}
	else
		return false;


	if (!isServer){
		useBeacon = true;
	}

	for (i=i; i < argc; i++){

		if (strcmp(argv[i], "-beacon") == 0 && argc >= i+2 && isServer){
			if (strcmp(argv[++i], "NONE") == 0){
				useBeacon = false;
				continue;
			}

			if (strcmp(argv[i], "BROAD") == 0 && argc >= i+2){
				useBeacon = true;
				useBroad = true;
				serverIP = argv[++i];
				continue;
			}
			printf("argc %i i %i\n", argc, i);
			if (strcmp(argv[i], "MULT") ==0 && argc >= i+2){
				useBeacon = true;
				useBroad = false;
				serverIP = argv[++i];
				continue;
			}
		}

		else if (strcmp(argv[i], "-beacon") == 0 && argc >= i+2 && !isServer){

			if (strcmp(argv[++i], "BROAD") == 0){
				useBeacon = true;
				useBroad = true;
				continue;
			}

			else if (strcmp(argv[i], "MULT") == 0){
				useBeacon = true;
				useBroad = false;
				continue;

			}
			else if (strcmp(argv[i], "NONE") == 0 && argc >= i+2){
				useBeacon = false;
				serverIP = argv[++i];
				continue;
			}
			else
				return false;
		}

		else if (strcmp(argv[i],"-port" ) == 0 && argc >= i+2){
                   appServerPort = atoi(argv[++i]);
                }
		else if (strcmp(argv[i],"-serial" ) == 0 && argc >= i+2){
			serialPort = argv[++i];
			if (strncmp(serialPort,"SOCK", 4) == 0) {
			   isSerialSock = true;
                        }
		}
		else if (strcmp(argv[i],"-gateIP" ) == 0 && argc >= i+2 && isServer){
			gateIP = argv[++i];
		}
		else if (strcmp(argv[i],"-quiet" ) == 0){
			isQuiet = true;

		}
		else
			return false;


	}




	return true;
}

static void printUsage(char **argv){
	printf("\n");
	printf("Client Mode: %s -c [options]\n",argv[0]);
	printf("	or\n");
	printf("Server Mode: %s -s [options]\n",argv[0]);
	printf("	or\n");
	printf("Simulator Bridge Mode: %s -m [options]\n\n",argv[0]);

	printf("options:\n");
	printf("-port [port_num] (default 9001)\n");
	printf("-serial [COM1|COM2|COM3|SOCK|NONE] (default NONE)\n");
	printf("-gateIP [ip_addr] (server option, default 127.0.0.1)\n");
	printf("-beacon [BROAD ip_addr|MULT ip_addr|NONE] (server option, default NONE)\n");
	printf("-beacon [BROAD|MULT|NONE ip_addr] (client option, default BROAD)\n");

	printf("-quiet (Will not print every packet in stdout)\n");
	printf("\n");

}

static void printStartUp(){
	printf("Starting %s Mode\n",isServer ? "Server" : "Client");
	if (isServer) printf("Connecting to gateway addresss %s\n",gateIP);
	printf("Beacon is %s\n",useBeacon ? "on" : "off");
	if (isServer && useBeacon) printf("%s server address %s\n",useBroad ? "Broadcasting" : "Multicasting",serverIP);
	if (!isServer && useBeacon) printf("Waiting for %s from server\n",useBroad ? "broadcast" : "multicast");
	if (!isServer && !useBeacon) printf("Connecting to server address %s\n",serverIP);

	printf("Using serial output %s\n",serialPort);
	printf("Quiet mode is %s\n",isQuiet ? "on" : "off");

	printf("\n");

}


static void signalHandler(int signum) {
	switch (signum) {

	case SIGHUP:
		printf("Exiting on SIGHUP\n");
		break;
	case SIGINT:
		printf("Exiting on SIGINT\n");
		break;
	case SIGTERM:
		printf("Exiting on SIGTERM\n");
		break;
	default:
		printf("Exiting on signal %d\n", signum);
	}

	exit(1);
}



int main( int argc, char **argv ){



	if (!getUsage(isServer, argc,argv)){
		printUsage(argv);
		return 1;
	}

	signal(SIGHUP, &signalHandler);
   	signal(SIGINT, &signalHandler);
   	signal(SIGTERM, &signalHandler);

	printStartUp();

	try{

                if (strcmp(serialPort, "NONE") != 0) {
		   if (isSerialSock){
                      ClientSocket* serial = new AsciiHexSerialClient();
                      char serialSocketHost[30];
                      int serialSockPort = UART_SERVER_PORT;

#if CONNECT_TO_LOCAL_ADDRESS
                      gethostname(serialSocketHost, 30);
#else
                      strcpy(serialSocketHost, "127.0.0.1");
#endif
                      if (strcmp(serialPort,"SOCK") != 0) {
                         // assumes format is SOCK:hostname or 
                         // SOCK:hostname:port
                         char * colon = index(&(serialPort[5]), ':');

                         if (colon != NULL) {
                            strncpy(serialSocketHost, &(serialPort[5]), 
                                    colon - &(serialPort[5]));
                            serialSockPort = atoi(colon+1);
                         } else {
                            strcpy(serialSocketHost, &(serialPort[5]));
                         }
                      }

                      serial->connect(serialSocketHost,serialSockPort,true);
                      conn.addIOStream(serial);
                      printf("%s is connected\n",serial->getName());
		   }
		   else {
			SerialPort* serial = new SerialPort(serialPort);
			conn.addIOStream(serial);
			printf("%s is connected\n",serial->getName());

                   }
		}



		if (isServer){
			ClientSocket* client = new SoftwareGatewayCommandClient();
			client->connect(gateIP,TOS_SIM_COMMAND_PORT,true);
			conn.addIOStream(client);
			printf("%s is connected\n",client->getName());

			client = new SoftwareGatewayEventClient();
			client->connect(gateIP,TOS_SIM_EVENT_PORT,true);
			conn.addIOStream(client);
			printf("%s is connected\n",client->getName());


			if (useBeacon){

				if (useBroad){
					BroadcastSocket* mSocket = new BroadcastSocket();
					mSocket->init(serverIP,DISCOVERY_PORT);
					conn.addIOStream(mSocket);
					mSocket->start();
				} else {
					MulticastSocket* mSocket = new MulticastSocket();
					mSocket->init(serverIP,MULTICAST_ADDRESS,DISCOVERY_PORT);
					conn.addIOStream(mSocket);
					mSocket->start();
				}
			}

			ServerSocket* server = new NodeServer();
			server->bindAndListen(NODE_SERVER_PORT);
			conn.addIOStream(server);

			server = new AsciiHexAppServer();
			server->bindAndListen(appServerPort);
			conn.addIOStream(server);


		}
		else if (isSimBridge){
			ClientSocket* client = new SoftwareGatewayCommandClient();
			client->connect(gateIP,TOS_SIM_COMMAND_PORT,true);
			conn.addIOStream(client);
			printf("%s is connected\n",client->getName());

			client = new SoftwareGatewayEventClient();
			client->connect(gateIP,TOS_SIM_EVENT_PORT,true);
			conn.addIOStream(client);
			printf("%s is connected\n",client->getName());

			ServerSocket* server = new NodeServer();
			server->bindAndListen(NODE_SERVER_PORT);
			conn.addIOStream(server);

			server = new AsciiHexAppServer();
			server->bindAndListen(appServerPort);
			conn.addIOStream(server);

			ClientSocket* nodeClient = new NodeClient();
			nodeClient->connect(serverIP,NODE_SERVER_PORT,true);
			conn.addIOStream(client);
			printf("%s is connected\n",nodeClient->getName());
                }
		else {

			if (!useBeacon){

				ClientSocket* client = new NodeClient();
				client->connect(serverIP,NODE_SERVER_PORT,true);
				conn.addIOStream(client);
				printf("%s is connected\n",client->getName());
			}
			else {
				if (useBroad){
					BroadcastSocket* mSocket = new BroadcastSocket();
					mSocket->init(0,DISCOVERY_PORT);
					conn.addIOStream(mSocket);
				}else {
					MulticastSocket* mSocket = new MulticastSocket();
					mSocket->init(0, MULTICAST_ADDRESS,DISCOVERY_PORT);
					conn.addIOStream(mSocket);
				}
			}
		}

	} catch(Exception* e){
		e->printErrorMsg();
		delete e;
		exit(1);
	}

	conn.start();
	return 0;

}



