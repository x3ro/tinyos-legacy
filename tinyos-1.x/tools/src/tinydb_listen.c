#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <stdint.h>

#include "sfsource.h"

#define PACKET_LENGTH 56 //5 header bytes, 29 body bytes, 2 crc bytes
#define BAUDRATE B57600 //the baudrate that the device is talking
#define SERIAL_DEVICE "/dev/ttyS3" //the port to use.

int input_stream;
char input_buffer[PACKET_LENGTH];

void print_usage(void);
void open_input(void);
void print_packet(void);
void read_packet(void);

int main(int argc, char ** argv) {
  if (argc == 3)
    {
      int fd = open_sf_source(argv[1], atoi(argv[2]));
      if (fd < 0)
	{
	  fprintf(stderr, "Couldn't open serial forwarder at %s:%s\n",
		  argv[1], argv[2]);
	  exit(1);
	}
      for (;;)
	{
	  int len;
	  unsigned char *packet = read_sf_packet(fd, &len);

	  if (len > PACKET_LENGTH)
	    printf("packet too long (len %d)\n", len);
	  else
	    {
	      memcpy(input_buffer, packet, len);
	      printf("DEST %d ", packet[0] | packet[1] << 8);
	      print_packet();
	    }
	}
    }
  else
    {
      print_usage();
      open_input();
      while(1){
	read_packet();
	print_packet();
      }
    }
}

void print_usage(){
    //usage...
	printf("usage: \n");
	printf("This program reads in data from");
	printf(SERIAL_DEVICE);
	printf(" and prints it to the screen.\n");
	printf("\n");
}


void open_input(){
    /* open input_stream for read/write */ 
    struct termios newtio;
    input_stream = open(SERIAL_DEVICE, O_RDWR|O_NOCTTY);
    if (input_stream == -1)
	perror(": input_stream open fails\n make sure the user has permission to open device.\n");
    printf("input_stream opens ok\n");

    /* Serial port setting */
    bzero(&newtio, sizeof(newtio));
    newtio.c_cflag = BAUDRATE | CS8 | CLOCAL | CREAD;
    newtio.c_iflag = IGNPAR | IGNBRK;

    /* Raw output_file */
    newtio.c_oflag = 0;
    tcflush(input_stream, TCIFLUSH);
    tcsetattr(input_stream, TCSANOW, &newtio);
}

#define MULTIHOP_LENGTH PACKET_LENGTH - 5
#define uint8_t unsigned char
#define uint16_t unsigned short
typedef struct AMMsg {
  uint16_t dest;
  uint8_t am_id;
  uint8_t grp_id;
  uint8_t len;
  uint8_t data[MULTIHOP_LENGTH]; 
}  __attribute__ ((packed)) TOSMsg;


    	
void read_packet(){
	int count;
	char c;
	int len,hdrlen=5;
	TOSMsg *m = (TOSMsg *)input_buffer;

	bzero(input_buffer, PACKET_LENGTH);
	//search through to find 0x7e signifing the start of a packet
    	while(input_buffer[0] != (char)(0x7e)){
	  //printf("%d,",input_buffer[0]);fflush(stdout);
	  while((c = read(input_stream, input_buffer, 1)) != 1){
	    //printf("%d,",c);fflush(stdout);
	  };
    	} 
	count = 1;
	//you have the first byte now read the rest.
	while(count < hdrlen) {
		count += read(input_stream, input_buffer + count, hdrlen - count); 	
	}
	len = m->len;
	if (len > PACKET_LENGTH) {
	  printf("bad packet (len = %d)\n",len);
	  len = PACKET_LENGTH;
	}
	while (count < len) {
	  count += read(input_stream, input_buffer + count, len - count); 	
	}

	
}



typedef struct  {
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;
  uint8_t data[MULTIHOP_LENGTH-7]; 
} __attribute__ ((packed)) TOS_MHopMsg;

typedef struct {
  uint8_t qid;
  uint8_t numFields;
  long notNull;
  char data[0];
} __attribute__ ((packed))  Tuple;

//for now, a query result is really just a tuple
typedef struct QueryResult {
  char qid; //note that this byte must be qid  //1
  int8_t result_idx; //2
  uint16_t epoch; //4
  uint8_t qrType; //6
  
  uint8_t timeSyncData[5];
  int16_t clockCount;
  int16_t diff;

  Tuple t;

}__attribute__ ((packed)) QueryResult, *QueryResultPtr;



  typedef struct RPEstEntry {
    uint16_t id;
    uint8_t receiveEst;
    //uint16_t lsn;
  } __attribute__ ((packed)) RPEstEntry;

  typedef struct RoutePacket {
    uint16_t parent;
    uint16_t cost; // XXX This has NO real use.
    //    uint8_t hop;  // XXX Is this already in the MH header??
    uint8_t estEntries;
    RPEstEntry estList[1];
  } __attribute__ ((packed)) RoutePacket;

  typedef struct QueryMessage {
    uint8_t qid;
    uint16_t fwdNode;
    char msgType;
    char numFields;
	char numExprs;
	char fromBuffer;
	uint8_t junk;
	uint16_t epochDuration;
	char type;
	char idx;
	char rest_of_struct[0];
  } __attribute__ ((packed)) QueryMessage;

  typedef struct QueryRequestMessage {
    uint8_t qid;
	uint32_t qmsgMask;
    uint16_t reqNode;
	uint16_t fromNode;
  } __attribute__ ((packed)) QueryRequestMessage;

  typedef struct CommandMessage {
    uint16_t nodeid;
	uint32_t seqNo;
	char data[0];
  } __attribute__ ((packed)) CommandMessage;

static char *
msgType(char type)
{
	switch (type) {
	case 0:
		return "ADD";
	case 1:
		return "DEL";
	case 2:
		return "MOD";
	case 3:
		return "RATE";
	case 4:
		return "DROP";
	}
	return "ERR";
}

static char *
qmsgType(char type)
{
	switch (type) {
	case 0:
		return "FIELD";
	case 1:
		return "EXPR";
	case 2:
		return "BUF";
	case 3:
		return "EVENT";
	case 4:
		return "EPOCH";
	case 5:
		return "DROP";
	}
	return "ERR";
}

void print_packet(){
  TOSMsg *m = (TOSMsg *)input_buffer;
  TOS_MHopMsg *msg = (TOS_MHopMsg *)m->data;
  time_t curt;

  int i;

  
  time(&curt);
  printf ("%s", ctime(&curt));

  if (m->am_id == 0xf0 || m->am_id == 107) { 
    QueryResultPtr qr = (QueryResultPtr)msg->data;
    
	printf("RESULT: ");
	printf("sender = %d, source = %d, ", msg->originaddr, msg->sourceaddr);

  
    printf("qid = %d, ", qr->qid);
    printf("epoch = %d, ", qr->epoch);
    printf("cc = %d,", qr->clockCount);
    printf("time = %d,", *(long *)&qr->timeSyncData[1]);
    printf("diff = %d,", qr->diff);
    printf("fwd = %d,", msg->sourceaddr);
    printf("hop = %d,", msg->hopcount);
    printf("seq = %d,", msg->seqno);
    
    if (qr->qrType == 2) { //is a non-aggregate record
      printf ("mask = ");
      for (i = 0; i < qr->t.numFields; i++) {
	if ((qr->t.notNull & (1 << i)) > 0)
	  printf("1");
	else
	  printf("0");
      }
      printf("\n");

      
    }
  } else if (m->am_id == 0xfa) {
    RoutePacket *rp = (RoutePacket *)msg->data;

	printf("ROUTE: ");
    printf ("beacon: %d,", msg->sourceaddr);
    printf ("parent: %d,", rp->parent);
    printf ("hop: %d,", msg->hopcount);
    printf ("cost: %d,", rp->cost);
    printf ("seq: %d\n    ", msg->seqno);
    if (rp->estEntries > 10) rp->estEntries = 10; //avoid bad packets
    for (i=0;i<rp->estEntries;i++) {
      printf ("(id:%d, q:%d),",
	      rp->estList[i].id,
	      rp->estList[i].receiveEst);
    } 
    printf ("\n");
	    
  } else if (m->am_id == 104) {
	int i;
	QueryRequestMessage *qreqMsg = (QueryRequestMessage*)m->data;
    printf ("QUERY REQ: %d requsts query %d from %d, mask = ", qreqMsg->reqNode, qreqMsg->qid, qreqMsg->fromNode);
      for (i = 0; i < 32; i++) {
	if ((qreqMsg->qmsgMask & (1 << i)) > 0)
	  printf("1");
	else
	  printf("0");
      }
	printf("\n");
  } else if (m->am_id == 101) {
	QueryMessage *qmsg = (QueryMessage*)m->data;
    printf ("QUERY: %d sends query message: qid = %d, msgType = %s, nFields = %d, nExprs = %d, epochDur = %d, type = %s, idx = %d\n", qmsg->fwdNode, qmsg->qid, msgType(qmsg->msgType), qmsg->numFields, qmsg->numExprs, qmsg->epochDuration, qmsgType(qmsg->type), qmsg->idx);
  } else if (m->am_id == 103) {
	  CommandMessage *cmsg = (CommandMessage*)m->data;
	  printf("COMMAND: command message to node %d, command = %s\n", cmsg->nodeid, cmsg->data);
  } else if (m->am_id == 105) {
	  printf("EVENT: event message\n");
  } else if (m->am_id == 106) {
	  printf("STATUS: status message\n");
  } else {
    printf ("UNKNOWN: heard am_id %d\n", m->am_id);
  }
  printf("\n");
  fflush(stdout);
} 
