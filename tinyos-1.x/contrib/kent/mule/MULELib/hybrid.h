/** hybrid.h
  * 
  * Header file for hybrid simulation functions.
  *
  * David G. Watson - dgwatson@kent.edu
  */

//#ifndef __HYBRID_H
//#define __HYBRID_H

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <sys/poll.h>
#include <time.h>
#include <termios.h>

#define HYBRID_CONFIG_FILE "hybrid.conf"
#define HYBRID_START_SYMBOL 'A'
#define HYBRID_TIMING_SYMBOL 'B'
#define HYBRID_DONE_SYMBOL '\n'
#define HYBRID_RECEIVE_PACKET_FROM_UART 'C'
#define HYBRID_SEND_LOCAL_ADDRESS 'D'

#define HYBRID_MIC_COMMAND 'E'
#define HYBRID_GET_DATA 'F'
#define HYBRID_GET_CONT_DATA 'G'
#define HYBRID_MUX_SEL 'H'
#define HYBRID_GAIN_ADJ 'I'
#define HYBRID_READ_TONE 'J'
#define HYBRID_INTERRUPT_ENABLE 'K'
#define HYBRID_INTERRUPT_DISABLE 'L'
#define HYBRID_PHOTO 'M'
#define HYBRID_DATA_READY 'N'

#define MY_SENSOR_SOCKET hybrid_state.sense_array[NODE_NUM]->fd
#define SOCKET(x) hybrid_state.mote_array[x]->fd

#define SENDING_RECORD_COUNT 10

// I put this here because the NesC compiler is RETARDED
ssize_t getline(char **lineptr, size_t *n, FILE *stream);

// TODO: Define structure to hold saved transmissions
//
// Needs to hold the following info:
// 1) Time taken to send
// 2) Reception for each member of array

typedef struct sending_record {
  uint16_t send_time[SENDING_RECORD_COUNT];
  char* received[SENDING_RECORD_COUNT];
  char* sendPattern;
  int count;
  struct sending_record* next;
} sending_record;

typedef struct {
  TOS_MsgPtr msg;
  int srcaddr;
} tossim_msg_event;

typedef struct {
  TOS_MsgPtr msg;
} tossim_senddone_event;

typedef struct {
  TOS_MsgPtr msg;
  uint16_t send_time;
  bool ackFirst;
  bool msgAcked;
  int node;
} hybrid_multi_ent;

typedef struct stringNode {
  char* data;
  struct stringNode* next;
} stringNode;

typedef struct {
  TOS_MsgPtr msg;
  long long startTime;
  bool isInQueue;
  int mote;
  uint16_t messageTime;
  uint8_t ack_buf[4];
  bool ackComesFirst;
  int assignedMote;
  bool actuallySent;
} hybrid_message;

typedef struct {
  int fd;
  int hwAddr;
  int motearray_xpos;
  int motearray_ypos;
} real_mote;

typedef struct {
  real_mote* mote_array[TOSH_NUM_NODES]; // used to get sockets for motes
  int transmitting[TOSH_NUM_NODES];
  bool anyoneTransmitting;
  hybrid_message* sending[TOSH_NUM_NODES];
  long long backoffTime;
  long totalSendTime;

  int physWidth;
  int physHeight;
  int simWidth;
  int simHeight;
  int centerX;
  int centerY;
  real_mote ** real_motes;
  real_mote ** virtual_motes;
  bool usingTiling;
  int usingCaching;

  sending_record* cachedSends;

  // for sensing
  real_mote * sense_array[TOSH_NUM_NODES];
} struct_hybrid_state;



struct_hybrid_state hybrid_state;
int hybrid_initialized = 0;

void setNonBlocking(int socketfd, int setting);

void free_sending_record(sending_record* rec) {
  free(rec->received);
  free(rec);
}

void free_string_list(stringNode* head) {
        stringNode* next_node;
        while (head) {
                free(head->data);
                next_node = head->next;
                free(head);
                head = next_node;
        }
}


bool hasDataAvailable(int socketfd, int usecs) {
  fd_set rfds;
  struct timeval tv;
  int retval;

  FD_ZERO(&rfds);
  FD_SET(socketfd, &rfds);

  tv.tv_sec = 0;
  tv.tv_usec = usecs;

  retval = select(socketfd+1, &rfds, NULL, NULL, &tv);
  if (retval) 
    return 1;
  else return 0;
}



int read_bytes(int socketfd, void* buf, size_t count) {
  setNonBlocking(socketfd, 1);
  while (count > 0) {
    int numread = read(socketfd, buf, count);
    if (numread == -1 && hasDataAvailable(socketfd, 1000000)) {
     continue;
    } else if (numread == -1) {
      //fprintf(stderr, "read_bytes: got -1\n");
      return count;
    }
    count -= numread;
    buf += numread;
    //fprintf(stderr, "%d bytes left\n", count);
  }
  return 0;
}

void allocStringNode(stringNode** head, stringNode** curr, char* data) {
  if (*head == 0) {
    *head = (stringNode*)malloc(sizeof(stringNode));
    *curr = *head;
  } else {
    (*curr)->next = (stringNode*)malloc(sizeof(stringNode));
    *curr = (*curr)->next;
  }
  (*curr)->next = NULL;
  (*curr)->data = data;
}


stringNode* read_hybrid_config_file(char* hybrid_filename) {
  stringNode* head = NULL, *curr = NULL;
  FILE* infile = fopen(hybrid_filename, "r");
  char* buf = NULL;
  int size;

  if (!infile) {
   fprintf(stderr, "MULE: Error: could not open file %s. Exiting.\n", 
	hybrid_filename);
    exit(-1);
  }


  while (getline(&buf, &size, infile) > 0) {
    // get rid of comments
    if (index(buf, '#')) {
      * (index(buf, '#')) = '\0';
    }

    // only allocate if line is not blank
    if (strlen(buf))  {
      allocStringNode(&head, &curr, buf);
    } else {
      free(buf);
    }
    buf = NULL;
  }

  return head;
}


void setNonBlocking(int fdToSet, int status) {
  int flags;

  if  ((flags = fcntl(fdToSet, F_GETFL, 0)) < 0) {
    fprintf(stderr, "MULE: Error: F_GETFL.\nExiting.\n");
  }

  if (!status) {
    if (flags & O_NONBLOCK) {
      flags ^= O_NONBLOCK;
    } else return;
  } else {
    flags |= O_NONBLOCK;
  }

  fcntl(fdToSet, F_SETFL, flags);
}

// Throws away any incoming input on this FD
void flush_incoming(int socketfd) {
  int c;
  setNonBlocking(socketfd, 1);
  while (read(socketfd, &c, 1) > 0) {
    //fprintf(stderr, "flushing: %d\n", c);
  }
}


// "Hardware" address is a bit of a misnomer. It actually
// retrieves the programmed mote address.
int retrieve_hardware_address(int nodefd) {
  uint8_t buf[4];
  int newHwAddr;
  buf[0] = HYBRID_SEND_LOCAL_ADDRESS;
  buf[1] = '\n';

  //fprintf(stderr, "retrieving address for node %d...", node);
  flush_incoming(nodefd);
  write(nodefd, buf, 2);

  setNonBlocking(nodefd, 0);

  bzero(buf, 4);

  if (hasDataAvailable(nodefd, 50000))
    read_bytes(nodefd, buf, 4);

  //dbg(DBG_USR2, "Got packet %02x %02x %02x %02x\n", buf[0], buf[1], buf[2], buf[3]);
  if (buf[0] != HYBRID_SEND_LOCAL_ADDRESS || buf[3] != HYBRID_DONE_SYMBOL) {
    fprintf(stderr, 
	"MULE: Error: unable to retrieve local address of mote.\n"
	"Got packet %02x %02x %02x %02x\n"
	"Exiting.\n", buf[0], buf[1], buf[2], buf[3]);
    exit(-1);
  }

  newHwAddr = (buf[1] << 8) | buf[2];
  if (newHwAddr == 2565 ||
	newHwAddr == 2624) {
    fprintf(stderr, 
	"MULE: Error: unable to retrieve local address of mote.\n"
	"Got packet %02x %02x %02x %02x\n"
	"Exiting.\n", buf[0], buf[1], buf[2], buf[3]);
    exit(-1);
  }

  dbg(DBG_USR2, "MULEPacketM: Address of mote is %d\n", newHwAddr);
  return newHwAddr;
}

int open_socket_connection(char* moteLocation) {
  int newSocket;
  if (strncmp("file:", moteLocation, 5) == 0) {
    newSocket = open(moteLocation + 5, O_RDWR|O_NOCTTY|O_SYNC);
    if (newSocket == -1) {
      fprintf(stderr, "MULE: Unable to open serial port %s.\nExiting\n",
	  moteLocation + 5);
      exit(-1);
    } else {
      // I don't think all this garbage in here actually succeeds in
      // doing anything. But I'll leave it in, because you never know! ;)
      //
      // Incidentally, the idea for this block here is so I won't have to
      // run minicom on each of the serial ports each time I reboot my 
      // machine.
      struct termios pts;
      tcgetattr(newSocket, &pts);
      pts.c_lflag &= ~ICANON;
      pts.c_lflag &= ~(ECHO | ECHOCTL | ECHONL);
      pts.c_cflag |= HUPCL;
      pts.c_cc[VMIN] = 1;
      pts.c_cc[VTIME] = 0;
      pts.c_oflag |= ONLCR;
      pts.c_iflag &= ~ICRNL;
      pts.c_cflag &= ~CRTSCTS;
      pts.c_iflag &= ~(IXON | IXOFF | IXANY);
      cfsetospeed(&pts, B57600);
      cfsetispeed(&pts, B57600);
      tcsetattr(newSocket, TCSANOW, &pts);
    }

  } else {
    struct sockaddr_in sa;
    struct hostent *hp;
    int portnumber;
    char* foobar;
    char* colonLoc;
    portnumber = 10002;
    foobar = malloc(strlen(moteLocation) + 1);
    strcpy (foobar, moteLocation);
    colonLoc = index(foobar, ':');

    if (colonLoc) { // port is specified
      portnumber = atoi(colonLoc + 1);
      *colonLoc = '\0';
    }
    fprintf(stderr, "portnum: %d\n", portnumber);



    if ((hp = gethostbyname(foobar)) == NULL) {
      fprintf(stderr, "MULE: Unknown host %s.\nExiting.\n",
	  moteLocation);
    }

    memset(&sa, 0, sizeof(sa));
    memcpy((char*)&sa.sin_addr, hp->h_addr, hp->h_length);
    sa.sin_family = hp->h_addrtype;
    sa.sin_port = htons((u_short)portnumber);

    if ((newSocket = 
	  socket(hp->h_addrtype, SOCK_STREAM, 0)) < 0) {
      fprintf(stderr, "MULE: Error connecting to %s on port %d.\nExiting.\n", 
	  moteLocation, portnumber);
      perror("Error was");
      exit(-1);
    }
    if (connect(newSocket, (struct sockaddr*)&sa, sizeof(sa)) 
	< 0) {
      close(newSocket);
      fprintf(stderr, "MULE: Error connecting to %s on port %d.\nExiting.\n", 
	  moteLocation, portnumber);
      perror("Error was");
      exit(-1);

    }
  }

  return newSocket;
}

void allocateTiledMoteGridsAndSetupConnections(stringNode* current) {
  int i, currMote = 0;
  real_mote* dummyMote = malloc(sizeof(real_mote));

  dummyMote->fd = -1;
  dummyMote->hwAddr = -1;
  for (i = 0; i < tos_state.num_nodes; i++) {
    hybrid_state.sense_array[i] = dummyMote;
  }
  
  // allocate grid of real motes
  hybrid_state.real_motes = calloc(hybrid_state.physWidth, sizeof(real_mote*));
  for (i = 0; i < hybrid_state.physWidth; i++) {
    int j;
    hybrid_state.real_motes[i] = calloc(hybrid_state.physHeight, sizeof(real_mote));
    for (j = 0; j < hybrid_state.physHeight; j++) {
      hybrid_state.real_motes[i][j].fd = -1;
      hybrid_state.real_motes[i][j].hwAddr = -1;
    }
  }

  // allocate grid of virtual motes
  hybrid_state.virtual_motes = calloc(hybrid_state.simWidth, sizeof(real_mote*));
  for (i = 0; i < hybrid_state.simWidth; i++) {
    int j;
    hybrid_state.virtual_motes[i] = calloc(hybrid_state.simHeight, sizeof(real_mote));
    for (j = 0; j < hybrid_state.simHeight; j++) {
      //fprintf(stderr, "Mote %d mapped to %d %d\n", currMote, i, j);
      hybrid_state.mote_array[currMote++] = &(hybrid_state.virtual_motes[i][j]);
    }
  }


  // read in mote data

  while (current != NULL) {
    int x, y, sensemote;
    char loc[100];
    real_mote* thismote = &(hybrid_state.real_motes[x][y]);

    sscanf(current->data, "%s %d %d %d", loc, &x, &y, &sensemote);
    fprintf(stderr, "sensemote: %d x %d y %d\n", sensemote, x, y);
    thismote->fd = open_socket_connection(loc);
    thismote->hwAddr = 
      retrieve_hardware_address(thismote->fd);
    thismote->motearray_xpos = x;
    thismote->motearray_ypos = y;
    hybrid_state.sense_array[sensemote] = thismote;

    current = current->next;
  }
}


// Sets up mote grids for the non-tiling case
void allocateStaticMoteGridsAndSetupConnections(stringNode* current) {
  int i;
  // just do it as a line (vertical, just because it's easier :)
  hybrid_state.simHeight = tos_state.num_nodes;
  hybrid_state.simWidth = 1;
  hybrid_state.virtual_motes = calloc(hybrid_state.simWidth, sizeof(real_mote*));
  hybrid_state.virtual_motes[0] = calloc(hybrid_state.simHeight, sizeof(real_mote));
  hybrid_state.real_motes = calloc(1, sizeof(real_mote*));
  hybrid_state.real_motes[0] = calloc(tos_state.num_nodes, sizeof(real_mote));

  for (i = 0; i < tos_state.num_nodes; i++) {
    char loc[100];
    if (current == NULL) {
      fprintf(stderr, "Insufficient physical nodes specified for number given to TOSSIM.\n"
	  "Exiting\n");
      exit(1);
    }

    sscanf(current->data, "%s", loc);

    hybrid_state.real_motes[0][i].fd = open_socket_connection(loc);
    hybrid_state.real_motes[0][i].hwAddr =
      retrieve_hardware_address(hybrid_state.real_motes[0][i].fd);

    hybrid_state.mote_array[i] = &(hybrid_state.real_motes[0][i]);
    hybrid_state.sense_array[i] = &(hybrid_state.real_motes[0][i]);

    current = current->next;
  }
}

void init_mote_connections(stringNode* first) {
  // we have very simple config file format - nothing fancy
  /* example config file:

# 13 motes in diamond configuration, simulating a grid
# motes must be on lattice points
# currently only 'grid' and 'notile' topologies are supported
topo grid
physwidth 5 # width of the physical simulation array
physheight 5 # 'height' of the physical simulation array
simwidth 6 
simheight 6 
centerx 2
centery 2

motes    

# address x y sensingmote
mote01.motenet 0 2 0
mote02.motenet 1 1 1
mote03.motenet 1 2 2
mote04.motenet 1 3 3
mote05.motenet 2 0 4
mote06.motenet 2 1 5
mote07.motenet 2 2 6
mote08.motenet 2 3 7
mote09.motenet 2 4 8
file:/dev/ttyS1 3 1 9
mote11.motenet 3 2 10
mote12.motenet 3 3 11
mote13.motenet 4 2 12

  */

  int topoType = 0;
  int doneflag = 0;
  stringNode* current = first;

  hybrid_state.physWidth = 0;
  hybrid_state.physHeight = 0;
  hybrid_state.simWidth = 0;
  hybrid_state.simHeight = 0;
  hybrid_state.centerX = 0;
  hybrid_state.centerY = 0;
  hybrid_state.usingCaching = 0;

  while (!doneflag) {
    char* foobuf;
    if (current == NULL)  {
      fprintf(stderr, "Incomplete configuration. Please recheck and try again.\n"
	  "Exiting\n");
      exit(1);
    }

    foobuf = strtok(current->data, " ");
    if (!foobuf) foobuf = current->data;

    if (!strcmp(foobuf, "topo")) {
      foobuf = strtok(NULL, " ");
      if (!strncmp(foobuf, "grid", 4)) {
	topoType = 1;
      }
      else if (!strcmp(foobuf, "notile"))  {
	topoType = 0;
      }
    } else if (!strcmp(foobuf, "physwidth")) {
      foobuf = strtok(NULL, " ");
      sscanf(foobuf, "%d", &hybrid_state.physWidth);
    } else if (!strcmp(foobuf, "physheight")) {
      foobuf = strtok(NULL, " ");
      sscanf(foobuf, "%d", &hybrid_state.physHeight);
    } else if (!strcmp(foobuf, "simwidth")) {
      foobuf = strtok(NULL, " ");
      sscanf(foobuf, "%d", &hybrid_state.simWidth);
    } else if (!strcmp(foobuf, "simheight")) {
      foobuf = strtok(NULL, " ");
      sscanf(foobuf, "%d", &hybrid_state.simHeight);
    } else if (!strcmp(foobuf, "centerx")) {
      foobuf = strtok(NULL, " ");
      sscanf(foobuf, "%d", &hybrid_state.centerX);
    } else if (!strcmp(foobuf, "centery")) {
      foobuf = foobuf;
      sscanf(strtok(NULL, " "), "%d", &hybrid_state.centerY);
    } else if (!strncmp(foobuf, "motes", 5)) {
      doneflag = 1;
    } else if (!strncmp(foobuf, "caching", 7)) {
      sscanf(strtok(NULL, " "), "%d", 
	  &hybrid_state.usingCaching);
    } else {
    }

    current = current->next;
  }


  switch(topoType) {
    case 0: // not using tiling
      hybrid_state.usingTiling = 0;
      allocateStaticMoteGridsAndSetupConnections(current);
      break;
    case 1: // grid-type (if you want linear, just set rows or columns to 1
      hybrid_state.usingTiling = 1;
      if (hybrid_state.simWidth * hybrid_state.simHeight != 
	  tos_state.num_nodes) {
	fprintf(stderr, "Error: you have run TOSSIM with %d motes, but\n"
	    "specified %d in the configuration file.\n"
	    "Please correct this, and run again.\nExiting.\n",
	    tos_state.num_nodes,
	    hybrid_state.simWidth * hybrid_state.simHeight
	    );
	exit(-1);
      }
      allocateTiledMoteGridsAndSetupConnections(current);
      break;
  }
}

// This is the magic master function! This method gets called once for
// each hybrid module on each running mote. But don't fret - I have guards
// in here so that it only does its business once! That's why this is outside
// of any one module, and hence in this header file.
void init_hybrid_sim() {
  stringNode* moteAddresses;
  stringNode* current;
  char* hybrid_config_filename;
  char * hybridenv;

  if (!hybrid_initialized)  {
      hybrid_initialized = 1;
  } else return;

  hybrid_state.cachedSends = NULL;

  hybridenv = getenv("HYBRIDTILE");
  if (!hybridenv) hybrid_state.usingTiling = 0;
  else if (strcmp(hybridenv, "y") == 0) 
    hybrid_state.usingTiling = 1;


  hybrid_config_filename = getenv("HYBRIDCONF");
  if (hybrid_config_filename == NULL) 
    hybrid_config_filename = HYBRID_CONFIG_FILE;
  moteAddresses = read_hybrid_config_file(hybrid_config_filename);
  current = moteAddresses;

  init_mote_connections(current);
  
  free_string_list(moteAddresses);
}



uint8_t simple_request(uint8_t channel, uint8_t to_send) {
  char buf[4];
  char retries = 0;
  buf [0] = to_send;
  buf [1] = channel;
  buf [2] = HYBRID_DONE_SYMBOL;

retry:
  write(MY_SENSOR_SOCKET, buf, 3);
  bzero(buf, 5);
  setNonBlocking(MY_SENSOR_SOCKET, 0);
  //fprintf(stderr, "s_r: reading... ");
  read_bytes(MY_SENSOR_SOCKET, buf, 4);
  //fprintf(stderr, "done\n");
  //fprintf(stderr, "got %02hhx %02hhx %02hhx %02hhx\n", 
  //    buf[0], buf[1], buf[2], buf[3]);
  // check stuff, and return result
  if (buf[0] == to_send &&
      buf[1] == channel &&
      buf[3] == HYBRID_DONE_SYMBOL)
    return buf[2];

  retries++;
  if (retries < 4) goto retry;
  //fprintf(stderr, "simple_request: Did not get valid packet back.\n");
  return FAIL;

}

uint8_t one_byte_request(uint8_t channel, uint8_t to_send, uint8_t arg) {
  char buf[4];
  char retries = 0;
  buf [0] = to_send;
  buf [1] = channel;
  buf [2] = arg;
  buf [3] = HYBRID_DONE_SYMBOL;

  fprintf(stderr, "sent %02hhx %02hhx %02hhx %02hhx\n", 
      buf[0], buf[1], buf[2], buf[3]);

retry:
  //fprintf(stderr, "o_b_r: writing... ");
  write(MY_SENSOR_SOCKET, buf, 3);
  //fprintf(stderr, "done\n");
  bzero(buf, 5);
  //fprintf(stderr, "o_b_r: reading... ");
  read_bytes(MY_SENSOR_SOCKET, buf, 4);
  //fprintf(stderr, "done\n");
  fprintf(stderr, "got %02hhx %02hhx %02hhx %02hhx\n", 
      buf[0], buf[1], buf[2], buf[3]);
  // check stuff, and return result
  if (buf[0] == to_send &&
      buf[1] == channel &&
      buf[3] == HYBRID_DONE_SYMBOL)
    return buf[2];

  fprintf(stderr, "one_byte_request: Did not get valid packet back.\n");
  retries++;
  if (retries < 4) goto retry;
  return FAIL;

}

//#endif // __HYBRID_H
