#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "sfsource.h"
#include "serialsource.h"
#include "platform.h"
serial_source src;
int server_socket;
int clifd = -1;
int packets_read, packets_written, num_clients;
int platform;

int unix_check(const char *msg, int result)
{
  if (result < 0)
    {
      perror(msg);
      exit(2);
    }

  return result;
}

void pstatus(void)
{
  printf("clients %d, read %d, wrote %d\n", num_clients, packets_read,
	 packets_written);
}


void open_server_socket(int port) {
  struct sockaddr_in me;
  int opt;

  server_socket = unix_check("socket", socket(AF_INET, SOCK_STREAM, 0));
//  unix_check("socket", fcntl(server_socket, F_SETFL, O_NONBLOCK));
  memset(&me, 0, sizeof me);
  me.sin_family = AF_INET;
  me.sin_port = htons(port);

  opt = 1;
  unix_check("setsockopt", setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR,
				     (char *)&opt, sizeof(opt)));
                                                                           
  unix_check("bind", bind(server_socket, (struct sockaddr *)&me, sizeof me));
  unix_check("listen", listen(server_socket, 5));
  if (DEBUG) {
    printf("DEBUG: opened socket %i\n", server_socket);
  } 
}

int accept_client(void) {
  printf("waiting for client...\n ");
  clifd = accept(server_socket, NULL, NULL);
  printf("accept returned with %i\n ", clifd);
  if (init_sf_source(clifd) < 0) {
    printf("client bad, reject\n");
    close(clifd);
    clifd = -1;
    return -1;
  }
  else {
    printf(" client good\n");
    return clifd;
  }
}

void stderr_msg(serial_source_msg problem)
{
  static char *msgs[] = {
    "unknown_packet_type",
    "ack_timeout"	,
    "sync"	,
    "too_long"	,
    "too_short"	,
    "bad_sync"	,
    "bad_crc"	,
    "closed"	,
    "no_memory"	,
    "unix_error"
  };

  fprintf(stderr, "Note: %s\n", msgs[problem]);
}

void open_serial(const char *dev, int baud)
{
    char ldev[80]; 
#ifdef __CYGWIN__
    int portnum;
    if (strncasecmp(dev, "COM", 3) == 0) {
	fprintf(stderr, "Warning: you're attempting to open a Windows rather that a Cygwin device.  Retrying with "); 
	portnum=atoi(dev+3);
	sprintf(ldev, "/dev/ttyS%d",portnum-1);
	fprintf(stderr,ldev);
	fprintf(stderr, "\n");
    } 
    
#else 
    strcpy(ldev, dev); 
#endif

  src = open_serial_source(ldev, baud, 0, stderr_msg);
  if (!src)
    {
      fprintf(stderr, "Couldn't open serial port at %s:%d\n", dev, baud);
      exit(1);
    }
}

int parsePlatform(char *platformName) {
    int platformGuess = AVRMOTE;
    if (strncasecmp(platformName, "mica2dot",8)==0) {
	platformGuess = AVRMOTE;
    } else if (strncasecmp(platformName, "mica2",5)==0) {
	platformGuess = AVRMOTE;
    } else if (strncasecmp(platformName, "mica", 4) == 0) {
	platformGuess = AVRMOTE;
    } else if (strncasecmp(platformName, "telos", 5) == 0) {
	platformGuess = TELOS;
    } else if (strncasecmp(platformName, "micaz", 5) == 0) {
	platformGuess = MICAZ;
    }
    return platformGuess;
}

#include <pthread.h>

pthread_t serial_to_socket_thread;
pthread_t socket_to_serial_thread;

void* serial_to_socket(void* x) {
  int len;
  int i;
  int count = 0;
  printf("starting serial reader thread.\n");
  while (1) {
    void* packet = read_serial_packet(src, &len);
    if (len > 0) {count++;}
    printf("read packet #%i (%p, %i bytes) from serial port...\n  ", count, packet, len);
    for (i = 0; i < len; i++) {
      printf("%02hhx ", ((uint8_t*)packet)[i]);
    }
    if (clifd < 0) {
      printf("no client connected, drop.\n");
    }
    else {
      int rval = write_sf_packet(clifd, packet, len);
      printf("wrote to socket\n");
      if (rval < 0) {
        if (DEBUG) {
 	  printf("error in serial_to_socket.\n");
          close(clifd);
	  return NULL;
        }
      }
    }
  }
}

void* socket_to_serial(void* x) {
  int len;
  int i;
  printf("starting socket to serial thread...\n");
  while (1) {
    void* packet = read_sf_packet(clifd, &len);
    printf("read %i byte packet (%p) from socket.\n", len, packet);
    for (i = 0; i < len; i++) {
      printf("%02hhx ", ((uint8_t*)packet)[i]);
    }
    if (packet == NULL) {  
      printf("ERROR in socket_to_serial.\n");
      pthread_cancel(serial_to_socket_thread);
      close(clifd);
      return NULL;
    }
    int rval = write_serial_packet(src, packet, len);
    printf("wrote packet to serial port.\n");
    if (rval < 0) {
      pthread_cancel(serial_to_socket_thread);
      printf("ERROR in socket_to_serial.\n");
      close(clifd);
      return NULL;
    }
  }
}


int main(int argc, char **argv)
{
  int serfd;

  if (argc != 5)
    {
      fprintf(stderr, "Usage: %s <port> <device> <rate> <platform> - act as a serial forwarder on <port>\n  (listens to serial port <device> at baud rate <rate>)\n assume that device connected to the serial port is a <platform> mote\nValid platforms: mica, mica2, mica2dot, avrmote, telos\n ", argv[0]);
      exit(2);
    }

  open_serial(argv[2], atoi(argv[3]));
  serfd = serial_source_fd(src);
  open_server_socket(atoi(argv[1]));
  platform = parsePlatform(argv[4]);

  while (1) {
    pthread_create(&serial_to_socket_thread, NULL, serial_to_socket, NULL);
    accept_client();
    sleep(1);
    pthread_create(&socket_to_serial_thread, NULL, socket_to_serial, NULL);
    
    pthread_join(serial_to_socket_thread, NULL);
    printf("joined with serial_to_socket.\n");
    pthread_join(socket_to_serial_thread, NULL);
    printf("joined with socket_to_serial.\n");
  }
}
