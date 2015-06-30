/**
 * Handles low-level socket communication.
 *
 * @file      xsocket.c
 * @author    Martin Turon
 * @version   2004/8/20    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xsocket.c,v 1.1 2005/03/31 07:51:06 husq Exp $
 */

#include "xsensors.h"

#include <sys/types.h>
#include <sys/socket.h>

#include <netdb.h>
#include <netinet/in.h>

#include <errno.h>

#define SOCKET_DEVICE      "localhost"   //!< Default hostname to use
#define SOCKET_PORT_SF     9001          //!< Serial Forwarder default port
#define SOCKET_PORT_MIB600 10002         //!< MIB600 default port
#define SOCKET_ERROR       -1

static const char *g_server   = SOCKET_DEVICE;
static unsigned    g_port     = SOCKET_PORT_SF;

/** Sets the hostname to connect to. */
void xsocket_set_server(const char *server) {
    if (!*server) return;
    g_server = server;
}

/** Returns the hostname to connect to. */
const char *xsocket_get_server() {
    return g_server;
}

/** Sets the tcp/ip port to connect to. */
void xsocket_set_port(const char *port) {
    if (!strcmp(port, "mib600")) {
	g_port = 10002;
    } else {
	g_port = atoi(port);
    }
}

/** Returns the tcp/ip port to connect to. */
unsigned xsocket_get_port() {
    return g_port;
}

int saferead(int fd, void *buffer, int count)
{
    int actual = 0;

    while (count > 0)
    {
	int n = read(fd, buffer, count);
	
	if (n == -1 && errno == EINTR)
	    continue;
	if (n == -1)
	    return -1;
	if (n == 0)
	    return actual;
	
	count -= n;
	actual += n;
	buffer += n;
    }
    return actual;
}

int safewrite(int fd, const void *buffer, int count)
{
    int actual = 0;
    
    while (count > 0)
    {
	int n = write(fd, buffer, count);
	
	if (n == -1 && errno == EINTR)
	    continue;
	if (n == -1)
	    return -1;
	
	count -= n;
	actual += n;
	buffer += n;
    }
    return actual;
}

int xsocket_start_sf(int fd)
/* Effects: Checks that fd is following the serial forwarder protocol
   Returns: 0 if it is, -1 otherwise
*/
{
    int platform = 0;
    char check[2];
    char nonce[6];
    /* Indicate version and check if serial forwarder on the other end
       (life is easy as we're the earliest protocol version) */
    nonce[0] = 'T'; nonce[1] = ' ';
    nonce[2] = (char)  (platform        & 0xff);
    nonce[3] = (char) ((platform >>  8) & 0xff);
    nonce[4] = (char) ((platform >> 16) & 0xff);
    nonce[5] = (char) ((platform >> 24) & 0xff);
    if (safewrite(fd, nonce, 6) != 6 ||
	saferead(fd, check, 6) != 6 ||
	check[0] != 'T' || check[1] < ' ')
    {
	return -1;
    }
    
    return 0;
}

/**
 * Opens up a stream to the tcp/ip socket port.
 * 
 * @return    Handle to the socket as an integer.
 * @author    Martin Turon
 * @version   2004/8/20       mturon      Intial revision
 */
int xsocket_port_open()
{
    const char *name = g_server;
    unsigned long port = g_port; 

    /* open socket for read/write */ 
    struct hostent    *l_host;
    struct sockaddr_in l_socket;
    int fd;
 
    l_socket.sin_family = AF_INET;
    l_socket.sin_port = htons(port);
    l_socket.sin_addr.s_addr = INADDR_ANY;
	
    l_host = gethostbyname(name);
    if (l_host == NULL) {
	printf("xsocket: Unknown host name: %s\n", name);
	exit(1);
    }
    memcpy(&(l_socket.sin_addr), l_host->h_addr, l_host->h_length);

    fd = socket(PF_INET, SOCK_STREAM, 0);
    if (fd == SOCKET_ERROR){
	fprintf(stderr, "xsocket: Failed to open %s\n", name);
	perror("");
	fprintf(stderr, "Verify that user has permission to open device.\n");
	exit(2);
    }
   
    while (connect(fd, (struct sockaddr *)&l_socket, sizeof(l_socket)) 
	   == SOCKET_ERROR) 
    {
	printf("xsocket: No response from %s...\n", name);
	sleep(1);
    }

//    int one = 1;
//    setsockopt(fd, SOL_SOCKET, SO_BROADCAST,(char *) &one, sizeof(one));
    
    if (xmain_get_verbose()) printf("%s input stream opened\n", name);

    xsocket_start_sf(fd);
    return fd;
}


