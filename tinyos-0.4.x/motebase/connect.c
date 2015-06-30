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


int readInt(char* buf, int offset);
int writeShortInt(int val, char* buf, int offset);
int readFull(int file, char* buf, int length);
int getFreeConnection();
int compSoFar;
#define CHECK_ERR(err, msg) { \
    if (err != Z_OK) { \
        fprintf(stderr, "%s error: %d\n", msg, err); \
        exit(1); \
    } \
}



#define MAXNUMCONNECTIONS 128
int connection;
int lastused[MAXNUMCONNECTIONS];
int main(int argic, char ** argv) {
  struct timeval start;
  int TotalXfered = 0;
  int startvalid = 0;
  struct timeval finish;
  int com1,i,stop=0;
  int count;
  int err;
  char radio[128000];
  char outbuf[10000];
  char compdata[10000];
  int compLen = 0;
  int sendLen = 0;
  char* header;
  char scratch[20];
  char statusreq[5] = {138, 1, 0,1 ,138}; 
  struct termios oldtio, newtio;
  int counter = 0;
  int inputfile;
  //initialize all connections.
 
  connection = -1;
  /* open com1 for read/write */ 
  com1 = open("/dev/ttyS0", O_RDWR|O_NOCTTY);
  //com1 = open("/dev/ttyp0", O_RDWR|O_NOCTTY);
  //com1 = open("/dev/irnine", O_RDWR|O_NOCTTY);
  if (com1 == -1)
    perror(": com1 open fails\n");
  printf("com1 opens ok\n");
  compSoFar = 0;

  /* save old serial port setting */
  tcgetattr(com1, &oldtio);
  bzero(&newtio, sizeof(newtio));

  newtio.c_cflag = BAUDRATE | CRTSCTS | CS8 | CLOCAL | CREAD;
  newtio.c_iflag = IGNPAR | ICRNL;


  /* Raw output */
  newtio.c_oflag = 0;

  tcflush(com1, TCIFLUSH);
  tcsetattr(com1, TCSANOW, &newtio);

  
  header = scratch + 9;
    char* data = radio + 9;
    
    int port;
    int length;
    char ip[4];
    struct sockaddr_in serv_addr;
    unsigned long addr;

    struct hostent *he;
  while(stop == 0) {
    err = readPacket(com1, data);
    printf("\n");
    for (i= 0; i < 30 && err == 1; i++) {
	printf("%d ", 0x000000FF & data[i]);
    }
	port = 7502;

	
   int connect(char* host, int port){
	memset((char *)&serv_addr, 0, sizeof(serv_addr));
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_port=htons((unsigned short)port);
	//he = gethostbyname((char*)(data + 4));
	
	//he = gethostbyname("pareto.cs.berkeley.edu");
	//he = gethostbyname("128.32.46.61");
	printf("looking up base\n");
	he = gethostbyname("pareto.cs.berkeley.edu");
	printf("done looking up base\n");
	addr =(unsigned long)
	    (((unsigned long)he->h_addr_list[0][0] & 0xFF)<<24L)|
	   (((unsigned long)he->h_addr_list[0][1] & 0xFF)<<16L)|
	    (((unsigned long)he->h_addr_list[0][2] & 0xFF)<<8L)|
	    (((unsigned long)he->h_addr_list[0][3] & 0xFF));
	serv_addr.sin_addr.s_addr=htonl(addr);

#ifdef CONNECTDEBUG
	printf("got port %d\n", port);
	printf("got hostname");
	printf("%s\n", data + 4);
	printf("got address %d.%d.%d.%d\n", 
	       he->h_addr_list[0][0] & 0xFF,
	       he->h_addr_list[0][1] & 0xFF,
	       he->h_addr_list[0][2] & 0xFF,
	       he->h_addr_list[0][3] & 0xFF);
	printf("remote host address is %1x\n", addr);
	printf("remote host address is %1x\n", ntohl(serv_addr.sin_addr.s_addr));
	printf("port number is %d\n", ntohs(serv_addr.sin_port));
		       
#endif
	connection = socket(AF_INET, SOCK_STREAM, 0);
#ifdef CONNECTDEBUG
	printf("connection #%d\n", connection);
	if(connection >= 0)
	printf("socket created.\n", port);
	else
	printf("socket create FAILED: %d, %d\n", errno, connection);
#endif
	err = connect(connection, &serv_addr, sizeof(struct sockaddr));
	if(0 == err){

#ifdef CONNECTDEBUG
	  printf("connected\n");
#endif
	  
	}else{
#ifdef CONNECTDEBUG
	  printf("connection failed  : %d : %d\n", err, errno);
#endif    
	}
	write(connection, data, 30);
     	
     

	printf("closing the connection: %d\n", connection);
	
	    close(connection);
	    connection = -1;

  }
    
  tcsetattr(com1, TCSANOW, &oldtio);
  close(com1);
}
int readInt(char* buf, int offset){
	return (((buf[offset]&0xFF) << 24) | ((buf[offset + 1]&0xFF) << 16) | ((buf[offset + 2]&0xFF) << 8) | (buf[offset + 3]&0xFF));
}

int readFull(int file, char* buf, int length){
  int count = 0;
  int loops = 0;
  int added = 0;
  printf("readFull called with length %d\n", length);
  while(count < length){
    added = read(file, buf+count, length - count);
    if(added > 0){
#ifdef READFULLDEBUG
	printf("read full: read %d, or %d of %d\n", added, count+added, length);
#endif
	count += added;
	loops = 0;
    }else{
      loops;
      if(loops > 4000 && count == 0) {
#ifdef READFULLDEBUG
	  if(count > 0) printf("read abort\n");
#endif
	  return -1;
      }
    }
  }
  return 1;
}

int readPacket(int file, char* buf){
    int err;
    err = readFull(file, buf, 38);
   return err;
}



