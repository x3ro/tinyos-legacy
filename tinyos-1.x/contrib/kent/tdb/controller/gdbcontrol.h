#ifndef __GDBCONTROL_H 
#define __GDBCONTROL_H
#include <stdio.h>


extern char* GDBARGS[];
extern int GDBARGCOUNT;

#define NORMAL 0x00
#define GETPID 0x01
#define STOPPEDMSGS 0x02
#define GETSOURCES 0x04
#define WATCHPOINT 0x08
#define ADDWATCH 0x10
#define FIRSTLINE 0x20
#define SECONDLINE 0x40
#define THIRDLINE 0x80
#define FOURTHLINE 0x100
#define BREAKPOINT 0x200
#define BREAKINFO 0x400
#define BREAKPOINTPAUSE 0x800

#define STOPPED 0
#define RUNNING 1
#define PAUSED 2


typedef struct breakpointNode {
	int breakpointNum;
	int address;
	struct breakpointNode* child;
	struct breakpointNode* next;	
} breakpointNode;


typedef struct {
  int gdbPid;
  int programPid;
  int socketfd;
  int gdbInFd;
  int gdbOutFd;
  int state;
  FILE* gdbWStream; 

  FILE* socketWStream, * socketRStream;

  char* programPath;
  char* command;
  int eventLoopFlag;
  int running;
  int skipcount;
  int stopExecAfterWatchpoint;
  int printDebug;
  int useCygwin;

  char* gdbQueuedCommands;
  char* currentCommandsPos;
  int* stopPoints;
  int numStopPoints;
  int maxStopPoint;
  breakpointNode* aliases;
} gdbControl;

extern gdbControl* control;

typedef struct stringNode {
  char* data;
  struct stringNode* next;
} stringNode;

void setNonBlocking(int fd, int status);

void makeCommandString(int argc, char** argv);

/* Get a single line of waiting input */
char* read_line(int fd);

/* Get all waiting input */
stringNode* getInput(int fd);

/* Create a read-write socket on port 7834 */
int createSocket();

/* sets up socket R/W streams */
void setUpSocketStreams();

/* prints contents of the string list to the stream.
   Each entry is on its own line. After the last entry is a line
   with a single period */
void printVars(stringNode* vars, FILE* outfile);

void initGDBControl(char ** args);

stringNode* extractVars(char* program);
stringNode* cygwinExtractVars(char* program);

void allocStringNode(stringNode** head, stringNode** curr, char* data);

void setNonBlocking(int fd, int status);

void eventLoop();

void startRunning();

void waitForInput();

char** makeArgs(int argc, char** argv);

// just read the (gdb) prompt
void readGDB();

void free_list(stringNode*);

void pauseExecution();
void resumeExecution();

void sendToSocket(const char*, ...);
void sendToGdb(const char*, ...);
void handleGdbInput(char* line);
void handleGetpidState(char* line);
void handleGetSourcesState(char* line);
void handleStoppedMsgsState(char* line);
void handleNormalState(char* line);
void handleGdbPrompt(char* line);

breakpointNode** getAliasAttachPoint(int address);
breakpointNode* getBreakpointAliases(int breakpointNum);
void minusOne(int* start, int count);
#endif
