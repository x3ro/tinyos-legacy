#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#define HOSTNAME "65.202.3.110"
#define oops(msg) {perror(msg); exit(-1);}
#define CLIENT_IO "r"
#define PORTNUM 5666

#define BUFFSIZE 256
#define READSIZE 128

int main(int argc, char * argv[])
{
  struct sockaddr_in saddr;
  struct hostent *hp;
  struct servent * serv_ent;
  int slen, s, rfd;
  register int i;
  FILE * rf;
  unsigned short buf0[BUFFSIZE], buf1[BUFFSIZE], buf2[BUFFSIZE], sector_request;

  if(argc == 1)
    sector_request = 500;   // some random number for server to read from flash
  else if(argc == 2)
    sector_request = atoi(argv[1]);
  else{
    fprintf(stderr, "syntax: %s <flash sector to read>\n");
    exit(0);
  }
  slen = sizeof(saddr);
  bzero(&saddr, slen);
  saddr.sin_family = AF_INET;
  if(!(hp = gethostbyname(HOSTNAME)))
    oops("Bad Hostname!");
  bcopy(hp->h_addr, &saddr.sin_addr, hp->h_length);

  saddr.sin_port = htons(PORTNUM);

  if((s = socket(AF_INET, SOCK_STREAM, 0)) == -1)
    oops("Bad Socket!");

  memset(buf0, ' ', BUFFSIZE * sizeof(unsigned short));
  memset(buf1, ' ', BUFFSIZE * sizeof(unsigned short));
  memset(buf2, ' ', BUFFSIZE * sizeof(unsigned short));

  while(connect(s, (struct sockaddr *)&saddr, slen));

  fprintf(stderr, "Connected\n");

  if(!(rf = fdopen(s, "r+")))
    oops("Bad fdopen!");
  fprintf(stderr, "opened...");
  
  fwrite(&sector_request, sizeof(unsigned short), 1, rf);
  fseek(rf, 0, SEEK_CUR);
  
  fread(buf0, READSIZE, 1, rf);
  fprintf(stderr, "read buffer 0...");
  fread(buf0 + READSIZE/2, READSIZE, 1, rf);
  fprintf(stderr, "read buffer 0a...");
  fread(buf0 + READSIZE, READSIZE, 1, rf);
  fprintf(stderr, "read buffer 0b...");
  fread(buf0 + 3*READSIZE/2, READSIZE, 1, rf);

  fprintf(stderr, "read buffer 1...");
    
  fread(buf1, READSIZE, 1, rf);
  fread(buf1 + READSIZE/2, READSIZE, 1, rf);
  fread(buf1 + READSIZE, READSIZE, 1, rf);
  fread(buf1 + 3*READSIZE/2, READSIZE, 1, rf);
    
  fprintf(stderr, "read buffer 2...");

  fread(buf2, READSIZE, 1, rf);
  fread(buf2 + READSIZE/2, READSIZE, 1, rf);
  fread(buf2 + READSIZE, READSIZE, 1, rf);
  fread(buf2 + 3*READSIZE/2, READSIZE, 1, rf);

  fprintf(stderr, "read buffer 3\n");
    
  fclose(rf);

  for(i = 0; i < BUFFSIZE; i++)
    fprintf(stderr, "[%4d] %d %d %d\n", i, *(buf0 + i), *(buf1 + i), *(buf2 + i));
  
}


