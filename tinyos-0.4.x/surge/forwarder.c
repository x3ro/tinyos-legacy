#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <sys/time.h>
#include "zlib.h"
#include <unistd.h>
#include <fcntl.h>
#define READHEADERDEBUG 1
#define READFULLDEBUG 1
#define CONNECTDEBUG 1
#define BAUDRATE B19200

int writePacket(int file, char* buf, int len);
int open_source();
int open_dest();
int readPacket(int file, int log, char* buf);
int writePacket(int file, char* buf, int len);
void printPacket(char* buf);
int create_connect(char* host, int port);

int main(int argc, char ** argv) {
   //open source
  
   int source;
   int dest = open_dest();
   int log;
   struct timeval sleep, oldtime, newtime;
   if (argc != 1) {
     source = open(argv[1], O_RDWR);
     log = 0; oldtime.tv_sec = 0;
   } else {
     source = open_source();
     log = creat("foo.data", S_IRWXU);
   }
     
   while(1 == 1){ //loop forever.
	char buf[100];
	int length;
	if (log) {
	  length = readPacket(source, log, buf);
	} else {
	  length = readRecord(source, buf, &newtime);
	  if (oldtime.tv_sec != 0) {
	    sleep.tv_sec = newtime.tv_sec - oldtime.tv_sec;
	    sleep.tv_usec = newtime.tv_usec - oldtime.tv_usec;
	    if (sleep.tv_usec < 0) {
	      sleep.tv_sec--; sleep.tv_usec += 1000000;
	    }
	    printf("Sleeping for %d sec %d usec\n", sleep.tv_sec, sleep.tv_usec);
	    select(0, NULL, NULL, NULL, &sleep); 
	  }
	  oldtime.tv_sec = newtime.tv_sec;
	  oldtime.tv_usec = newtime.tv_usec;
	}
	printPacket(buf);
	writePacket(dest, buf + 1, length);
   }
}

int readRecord(int file, char * buf, struct timeval *tv) { 
  int err = 0;
  err = read(file, tv, sizeof(struct timeval));
  err += read(file, buf,   38);
}

int readPacket(int file, int log, char* buf){
    int err = 0;
    struct timeval tv;
    buf[0] = 0;
    buf[1] = 0;
    while(buf[0] != 0x7e || buf[1] != 0x6){
	buf[0] = buf[1];
	while(1 != read(file, buf + 1, 1)){};
    }	
    err = 2;
    while(err < 30){
    	err += read(file, buf + err, 30 - err);
    }
    if (log != 0) {
      gettimeofday(&tv, NULL);
      write(log, &tv, sizeof(struct timeval));
      write(log, buf, 38);
    }
    return err;
}

int writePacket(int file, char* buf, int len){
    int err;
    err = write(file, buf, 38);
   return err;
}

void printPacket(char* buf){
    int place;
    for(place = 0; place < 30; place++){
	printf("%d,", buf[place] & 0xff);
    }
    printf("\n");
}

int open_source(){  
  return open_com_port();
  return open("foo.data", O_RDWR);

}
int open_com_port(){
  struct termios oldtio, newtio;
  int com1 = open("/dev/ttyS0", O_RDWR|O_NOCTTY);
  if (com1 == -1){
    perror(": com1 open fails\n");
    exit(-1);
  }
  printf("com1 opens ok\n");

  /* save old serial port setting */
  tcgetattr(com1, &oldtio);
  bzero(&newtio, sizeof(newtio));

  newtio.c_cflag = BAUDRATE | CRTSCTS | CS8 | CLOCAL | CREAD;
  newtio.c_iflag = IGNPAR | ICRNL;


  /* Raw output */
  newtio.c_oflag = 0;
  tcflush(com1, TCIFLUSH);
  tcsetattr(com1, TCSANOW, &newtio);
  return com1;
}

int open_dest(){
    return create_connect("127.0.0.1", 8765);
}
  
int create_connect(char* host, int port){
    int connection;
    struct hostent *he;
    struct sockaddr_in serv_addr;
    unsigned long addr;
    int err;
	memset((char *)&serv_addr, 0, sizeof(serv_addr));
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_port=htons((unsigned short)port);
	printf("looking up host\n");
	he = gethostbyname(host);
	printf("done looking up base\n");
	addr =(unsigned long)
	    (((unsigned long)he->h_addr_list[0][0] & 0xFF)<<24L)|
	   (((unsigned long)he->h_addr_list[0][1] & 0xFF)<<16L)|
	    (((unsigned long)he->h_addr_list[0][2] & 0xFF)<<8L)|
	    (((unsigned long)he->h_addr_list[0][3] & 0xFF));
	serv_addr.sin_addr.s_addr=htonl(addr);
	connection = socket(AF_INET, SOCK_STREAM, 0);
	printf("connection #%d\n", connection);
	if(connection >= 0){
		printf("socket created.\n");
	}else{
		printf("socket create FAILED: %d, %d\n", errno, connection);
	}
	err = connect(connection, &serv_addr, sizeof(struct sockaddr));
	if(0 == err){
	  printf("connected\n");
	}else{
	  printf("connection failed  : %d : %d\n", err, errno);
	  exit(-1);
	}
	return connection;
  }
	
