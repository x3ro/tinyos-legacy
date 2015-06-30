#include "gdbcontrol.h"
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>

gdbControl* control = NULL;
char * GDBARGS[] = { "--readnow", "--quiet",  "--args"};
int GDBARGCOUNT = sizeof(GDBARGS)/sizeof(char*);

void freeBreakpointAliases() {
	breakpointNode* curr = control->aliases;
	
	while (curr) {
		while (curr->child) {
			breakpointNode* tmp = curr->child;
			curr->child = curr->child->child;
			free(tmp);	
		}
		breakpointNode* tmp = curr;
		curr = curr->next;
		free(tmp);
	}
	control->aliases = NULL;
}

breakpointNode** getAliasAttachPoint(int address) {
	if (control->aliases == 0)
		return &(control->aliases);

	breakpointNode* curr= control->aliases;
	while (curr->address != address) {
		if (curr->next == 0)
			return &(curr->next);
		else curr = curr->next;
	}

	while (curr->child) 
		curr = curr->child;
	return &(curr->child);	
}

void sigintHandler(int signal) {
	fprintf(stderr, "Shutting down...\n");
	if (control->programPid > -1)
		kill(control->programPid, SIGKILL);
	kill(control->gdbPid, SIGKILL);
	exit(0);
}

void makeCommandString(int argc, char** argv) {
	int total = 16; // we need "run .... >/dev/null"
	int i;
	for (i = 2; i < argc; i++) {
		total += strlen(argv[i]) + 1;
	}
	
	control->command = (char*) calloc(total, sizeof(char));
	
	int currPos = 0;
	currPos += sprintf(control->command, "run ");
	for (i = 2; i < argc; i++) {
		currPos += sprintf(control->command + currPos, "%s ",
			argv[i]);
	}
}

/* Creates an array with the contents of argv and GDBARGS, suitable for
 * passing to execvp */
char** makeArgs(int argc, char** argv) {
	int numArgs = argc + sizeof(GDBARGCOUNT) + 1; // need space for GDBARGS
	char ** arglist = (char**) calloc(numArgs, sizeof(char*));

	arglist[0] = "gdb";
	int i;
	for (i = 1; i < sizeof(GDBARGCOUNT); i++)
		arglist[i] = GDBARGS[i-1];

	
	for (; i < sizeof(GDBARGCOUNT) + argc - 1; i++) 
		arglist[i] = argv[i - sizeof(GDBARGCOUNT) + 1];
	
	arglist[i] = NULL;

	return arglist;
}


void sendCommand(char* command) {
	if (control->useCygwin) {
		// need to queue up commands...
		if (control->running == PAUSED)
			sendToGdb("%s\n", command);
		else control->currentCommandsPos += 
			sprintf(control->currentCommandsPos, "%s\n", command);
	} else {
		int shouldStart = 0;
		if (control->running == RUNNING)  {
			pauseExecution();
			shouldStart = 1;
		}
		sendToGdb("%s\n", command);
		//fflush(control->gdbWStream);
		if (shouldStart) {
			resumeExecution();
		}
	}
}

void startRunning() {
	sendToGdb("set environment DBG=\nset prompt\nset width 400\ndisplay tos_state.current_node\n");
	control->skipcount++;
	if (control->useCygwin) {
		sendToGdb("break TOSH_run_next_task\n");
		sendToGdb("%s\n", control->command);
		sendToGdb("info program\n");
		sendToGdb("continue\n");
		fflush(control->gdbWStream);
		control->running = RUNNING;
	} else {
		sendCommand(control->command);
		control->running = RUNNING;
	}
}

int max(int a, int b) {
	if (a > b) return a;
	return b;
}

void handleGdbPrompt(char* line) {
	// if this is all there is, do nothing
	int length = strlen(line);
	if (length == 6) {
	} else {
		char* linewithoutgdb = 
			(char*)malloc(length - 5);
		strcpy(linewithoutgdb, line + 6);
		handleGdbInput(linewithoutgdb);
	}
}

void ensureEnoughStopPoints(int pointNum) {
	if (control->numStopPoints <= pointNum + 1) {
		control->stopPoints = (int*) realloc(control->stopPoints,
			sizeof(int) * (control->numStopPoints + 20));
		minusOne(control->stopPoints + 20, 20);
		control->numStopPoints += 20;
	}
}


void handleWatchpointStart(char* line) {
	int pointNum;
	sscanf(line + 20, "%d", &pointNum);

	ensureEnoughStopPoints(pointNum);

	if (control->stopPoints[pointNum] == -1) {
		control->stopPoints[pointNum] = 1;
		control->maxStopPoint++;
		sendCommand("info breakpoints");
	} else {
		control->state |= WATCHPOINT;
		control->state |= FIRSTLINE;
		sendToSocket(line);
		if (control->stopExecAfterWatchpoint) {
			control->running = PAUSED;
		} else {
			sendToGdb("continue\n");
		}
	}
}

void handleCygwinMainBreakpoint(char* line) {
	control->skipcount += 1;
	if (control->gdbQueuedCommands != 
		control->currentCommandsPos) {
		sendToGdb(control->gdbQueuedCommands);
		bzero(control->gdbQueuedCommands, 2000);
		control->currentCommandsPos = 
			control->gdbQueuedCommands;		
	}
	sendToGdb("ignore 1 1000\ncontinue\n");
}

void handleWatchpoint(char* line) {
	if (control->state & FIRSTLINE) {
		control->state ^= (FIRSTLINE | SECONDLINE);
		sendToSocket(" was %s, now ", line + 12);
	} else if (control->state & SECONDLINE) {
		control->state ^= (SECONDLINE | THIRDLINE);
		sendToSocket("%s\n", line + 12);
	} else if (control->state & THIRDLINE) {
		control->state ^= (THIRDLINE | FOURTHLINE);
		sendToSocket("%s\n", line);
	} else if (control->state & FOURTHLINE) {
		control->state ^= (FOURTHLINE| WATCHPOINT);
		sendToSocket("%s\n", line);
	}
}

void handleNewBreakpoint(char* line) {
	sendCommand("info breakpoints");
	control->maxStopPoint++;
}

void handleBreakpoint(char* line) {
	static char output[300];
	static char * outputPos;
	static int enqueueOutput;
	static int stopPointNum;
	if (!(control->state & BREAKPOINT)) {
		control->running = PAUSED;
		control->state |= BREAKPOINT;
		enqueueOutput = 1;
		bzero(output, 300);
		outputPos = output + sprintf(output, "%s\n", line);
		sscanf(line + 11, "%d", &stopPointNum);
	} else if (enqueueOutput) {
		if (strstr(line, "1: tos_state.current_node = ")) {
			enqueueOutput = 0;
			control->state ^= BREAKPOINT;
			control->state |= BREAKPOINTPAUSE;

			int num;
			sscanf(line + 28, "%d", &num);
			breakpointNode* node = 
				getBreakpointAliases(stopPointNum);
			
			if (!node) {
				if ((control->stopPoints[stopPointNum] == -1) ||
				    (control->stopPoints[stopPointNum] == num)){
					sendToSocket(output);
					sendToSocket("CurrentMote %d\n", num);
					return;
				}
			}

			while (node) {
				if ( (control->stopPoints[node->breakpointNum] 
						== -1) || 
				     (control->stopPoints[node->breakpointNum] 
						== num)) {	
					sendToSocket(output);
					sendToSocket("CurrentMote %d\n", num);
					return;
				} else node = node->child;
			}
			sendToGdb("continue\n");
		} else {
			outputPos += sprintf(outputPos, "%s\n", line);
		}
	} else {
		if (strstr(line, "Continuing.")) {
			control->running = RUNNING;
		} else if (strstr(line, "1: tos_state.current_node = ")) {
		} else {
			sendToSocket("%s\n", line);
		}
	}
}

void handleNormalState(char* line) {
	if (control->programPid == -1)	{
		control->state |= GETPID;
		if (control->useCygwin)  {
			control->skipcount += 5;
			control->maxStopPoint++;
		}
	} else if (strstr(line, 
		"warning: Could not remove hardware watchpoint") || 
		strstr(line, "Warning:")) {
	} else if (strstr(line, "Could not insert hardware watchpoint ")) {
		char foo[5];
		strcpy (foo, rindex(line, ' '));
		foo[strlen(foo) - 1] = 0;
		sendToGdb("disable%s\n", foo);
	} else if (strstr(line, "Could not insert hardware breakpoints:")) {
		control->skipcount++;
		sendToGdb("info breakpoints\ncontinue\n");
	} else if (control->useCygwin && 
			strstr(line, "Breakpoint 1, TOSH_run_next_task ()")) { 
		handleCygwinMainBreakpoint(line);
	} else if (strstr(line,"Breakpoint") && strstr(line, " at 0x") &&
		strstr(line, ": file")) {
		handleNewBreakpoint(line);
	} else if (strstr(line,"Breakpoint")  &&
		(!strstr(line, ", line"))) {
		handleBreakpoint(line);
	} else if (strstr(line, "No breakpoints")) {
		sendToSocket("SENDING BREAKPOINTS\n.\n");
	} else if(strstr(line, " at ") && 
		(strstr(line, ".nc:") || strstr(line, ".c:") || 
			strstr(line, ".h:"))) {
		if (control->state & BREAKPOINTPAUSE) {
			sendToSocket("%s\n", line);
		} else {
			control->skipcount++;
			control->state ^= STOPPEDMSGS;
		}
	} else if (strstr(line, "Source files for which symbols have been read in:")) {
		control->state |= GETSOURCES;
		sendToSocket("SENDING SOURCES\n");
	} else if (strstr(line, "(gdb)")) {
		handleGdbPrompt(line);		
	} else if (strstr(line, "Program received signal SIGINT")) {
		control->state |= STOPPEDMSGS;
	} else if (strstr(line,"Hardware watchpoint")) {
		handleWatchpointStart(line);
	} else if (strstr(line,"Num Type") 
		&& strstr(line, "Disp Enb Address")) {
		freeBreakpointAliases();
		sendToSocket("SENDING BREAKPOINTS\n");
		control->state |= BREAKINFO;
		if (control->useCygwin) control->skipcount++;
	} else if (strstr(line,"SIGPIPE")) {
		control->eventLoopFlag = 0;
		sendCommand("quit\ny");
	} else if (strstr(line,"[New Thread")) {
	} else if (strstr(line, "[Switching to Thread")) {
		control->skipcount++;
	} else if (strstr(line,"Will ignore next ")) {
	} else if (strstr(line, "1: tos_state.current_node = ")) {
	} else if (strstr(line, "Note: breakpoint") 
		&& strstr(line, "also set at pc")) {
	} else if (strstr(line, "Continuing.")) {
		control->running = RUNNING;
		if (control->state & BREAKPOINTPAUSE)
			control->state ^= BREAKPOINTPAUSE;
	} else if (line == NULL) {
	} else {
		sendToSocket("%s\n", line);
	}
}

/* Gives the list of aliases for the given breakpoint.
   breakpointNum: 	the number of the breakpoint in question
	
   returns a breakpointList with all the aliases of this breakpoint
*/
breakpointNode* getBreakpointAliases(int breakpointNum) {
	breakpointNode* currTop = control->aliases;
	while (currTop) {
		if (currTop->breakpointNum == breakpointNum)
			return currTop;
		breakpointNode *curr = currTop->child;
		while (curr) {
			if (curr->breakpointNum == breakpointNum)
				return currTop;
			curr = curr->child;
		}
		currTop = currTop->next;
	}
	return NULL;

}

void handleStoppedMsgsState(char* line) {
	if (strstr(line, "Switching to Thread")) {	
	} else if (strstr(line, "0x") && strstr(line, " in ")) { 
		if(strstr(line, " at ") && 
			(strstr(line, ".nc:") || strstr(line, ".c:") || 
			strstr(line, ".h:"))) 
		{
			control->skipcount++;
			control->state ^= STOPPEDMSGS;
		} else {
			control->state ^= STOPPEDMSGS;
		}
	} else if (strstr(line, " at ") && 
		(strstr(line, ".nc:") || strstr(line, ".c:") || 
			(line, ".h:"))) {
		control->state ^= STOPPEDMSGS;
		control->skipcount++;
	}
}

void handleGetpidState(char* line) {
	if (control->useCygwin) {
		char* start = rindex(line, ' ') + 1;
		int length = index(line, '.')  - start;
		char process[7];
		bzero(process, 7);
		strncpy(process, start, length);
		sscanf(process, "%d", &(control->programPid));
		control->skipcount += 2;
		control->state ^= GETPID; 
	} else {
		char* spacepos;
		spacepos = rindex(line, ' ');					
		char process[7];
		bzero(process, 7);
		strncpy(process, spacepos + 1,
			strlen(spacepos +1) - 2);
		sscanf(process, "%d", &(control->programPid));
		control->skipcount+=2;
		control->state ^= GETPID;
	}
}

void handleGetSourcesState(char* line) {
	if (!strcmp(line, "Source files for which symbols will be read in on demand:")) {
		sendToSocket(".\n");
		control->state ^= GETSOURCES;	
	} else {
		char buf[120];
		while (1) {
			bzero(buf, 120);
			if (sscanf(line, "%s", buf) != 1)
				break;
			line += strlen(buf);
			if (!(strstr(buf, ".nc") || strstr(buf, ".c") 
				|| strstr(buf, ".h"))) 
				continue;

			if (buf[strlen(buf)-1] == ',')
				buf[strlen(buf)-1] = 0;
			sendToSocket("%s\n", buf);
		}
	}
}

void handleBreakInfo(char* line) {
	if (strstr(line, "breakpoint already hit")) {
	} else if ((strstr(line, "breakpoint") && strstr(line, " at "))) {
		sendToSocket("%s\n", line);

		int num;
		sscanf(line, "%d", &num);
		if (control->stopPoints[num] != -1)
			sendToSocket("MOTE %d\n", control->stopPoints[num]);

		if (line[24] == 'y') { // is currently enabled
			int address;
			sscanf(line + 27, "%i", &address);
			
			breakpointNode* newNode = (breakpointNode*)malloc(sizeof(breakpointNode));
			newNode->address = address;
			newNode->child = NULL;
			newNode->next = NULL;
			newNode->breakpointNum = num;
			*(getAliasAttachPoint(address)) = newNode;
		}
	} else if (strstr(line, "hw watchpoint")
		|| strstr(line, "read watchpoint")) {
		sendToSocket("%s\n", line);
	} else {
		sendToSocket(".\n");
		control->state ^= BREAKINFO;
		handleGdbInput(line);
	}
}

void handleGdbInput(char* line) {
	if (control->printDebug) fprintf(stderr, "gdb says: %s\n", line);
	if (control->skipcount) {
		control->skipcount--;
	} else if(strlen(line) == 0) {
		// ignore this line
	} else if (control->state & GETPID) {
		handleGetpidState(line);
	} else if (control->state & ADDWATCH) {
		control->state ^= ADDWATCH;
		sendToSocket("Added %s\n", line);
	} else if (control->state & GETSOURCES) {
		handleGetSourcesState(line);
	} else if (control->state & STOPPEDMSGS) {
		handleStoppedMsgsState(line);		 
	} else if (control->state & WATCHPOINT) {
		handleWatchpoint(line);
	} else if (control->state & BREAKINFO) {
		handleBreakInfo(line);
	} else if (control->state & BREAKPOINT) {
		handleBreakpoint(line);
	} else { 
		handleNormalState(line);	
	}
}

void free_list(stringNode* head) {
	stringNode* next;
	while (head) {
		free(head->data);
		next = head->next;
		free(head);
		head = next;
	}
}

void initMoteBreakpoint(char* line) {
	int num;
	sscanf(line, "%d", &num);
	control->stopPoints[control->maxStopPoint+1] = num;
}

void handleSocketInput(char* line) {
	if (control->printDebug) fprintf(stderr, "%s\n", line);
	if (!(strncmp("run", line, 3))) {	
		sendCommand(control->command);
	} else if (!strncmp("quit", line, 4)) {
		control->eventLoopFlag = 0;
		sendCommand("quit\ny");
	} else if (!strncmp(line, "SENDLIT ", 8)) {
		sendCommand(line + 8);
	} else if (!strncmp(line, "break", 5)) {
		sendCommand(line);	
	} else if (!strncmp(line, "print", 5)) {
		sendCommand(line);	
	} else if (!strncmp(line, "info", 4)) {
		sendCommand(line);	
	} else if (!strncmp(line, "watch", 5)) {
		sendCommand(line);	
	} else if (!strncmp(line, "MOTE ", 5)) {
		initMoteBreakpoint(line + 5);
	} else if ((!strncmp(line, "next", 4)) || 
			(!strncmp(line, "step", 4)) || 
			(!strncmp(line, "list", 4))) {
		sendCommand(line);
	} else if (strstr(line, "current")) {
		sendCommand("print tos_state.current_node");
	} else if (!strncmp(line, "delete ", 7)) {
		if (control->useCygwin) {
			int pointNum = -1;
			sscanf(line + 7, "%d", &pointNum);
			if (pointNum > 1) sendCommand(line);
		} else {
			sendCommand(line);	
		}
	} else if (!strncmp(line, "print", 5)) {
		sendCommand(line);	
	} else if (!strncmp(line, "cont", 4)) {
		resumeExecution();
	} else if (strstr(line, "vars")) {
		sendToSocket("SENDING VARS\n");
		stringNode* vars;
		//if (control->useCygwin) 
			vars = cygwinExtractVars(control->programPath);
		//else 
			//vars = extractVars(control->programPath);
		printVars(vars, control->socketWStream);
		free_list(vars);
	} else if (strstr(line, "togglecontinue")) {
		control->stopExecAfterWatchpoint = 
			!control->stopExecAfterWatchpoint;
		if (control->stopExecAfterWatchpoint) {
			sendToSocket("STOPMODE\n");
		} else sendToSocket("CONTMODE\n");
	} else if (strstr(line, "delete")) {
		sendCommand(line);
	} else if (strstr(line, "stop")) {
		pauseExecution();
	}


}

void resumeExecution() {
	if (control->running == PAUSED) {
		sendCommand("continue");
		control->running = RUNNING;
	}
}

void eventLoop(void) {
	fd_set rset;
	int maxfdp1;

	FD_ZERO(&rset);
	control->state = NORMAL;
	control->eventLoopFlag = 1;
	

	while(control->eventLoopFlag) {
		FD_ZERO(&rset);
		FD_SET(control->gdbInFd, &rset);	
		FD_SET(control->socketfd, &rset);
		maxfdp1 = max(control->gdbInFd, control->socketfd) + 1;
		select(maxfdp1, &rset, NULL, NULL, NULL);

		if (FD_ISSET(control->gdbInFd, &rset)) {
			//fprintf(stderr, "data from gdb\n");
			char* line;
			while (line = read_line(control->gdbInFd)) {
				handleGdbInput(line);	
				free(line);
			}
		}
		if (FD_ISSET(control->socketfd, &rset)) {
			//fprintf(stderr, "data from socket\n");
			char* line;
			while (line = read_line(control->socketfd)) {
				handleSocketInput(line);	
				free(line);
			}
		}
		if (!FD_ISSET(control->socketfd, &rset) && 
			!FD_ISSET(control->gdbInFd, &rset)) {
			// closed on other end?
			sendCommand("quit\ny");
			control->eventLoopFlag = 0;
		}
		
	}

}

char* _read_line(int fd) {
	char *line;
	line = (char*)calloc(10000, sizeof(char));
	if (!line)  {
		perror("unable to allocate mem");
		exit(3);
	}

	
	char* curr = line;
	int result;
	
	while (1) {
		if (curr > line+9999) {
			*curr = '\0';
			return line;
		}
		result = read(fd, curr, 1);
		if (result < 1 && curr == line) {
		//	fprintf(stderr, "result: %d\n", result);
			free(line);
			return NULL;
		} else if (result < 1 || *curr == '\n') {
			*curr = '\0';
		//	fprintf(stderr, "result: %d line: %s\n", result, line);
			break;
		} else if (*curr == '\r') {
			continue;
		}
		curr++;
	}

	int size = strlen(line) + 1;
	if (line[size-2] == '\r') {
		line[size-2] == '\0';
		size--;
	}

	line = (char*)realloc(line, sizeof(char)*size);

	return line;
}

char* read_line(int fd) {
	setNonBlocking(fd, 1);
	return _read_line(fd);
}

stringNode* getInput(int fd) {
	stringNode* head, *curr;
	head = NULL;		
	curr = NULL;
	char* line;

	while((line = read_line(fd)) != NULL) {
		fprintf(stderr, line);
		if (head == NULL) {
			head = (stringNode*)malloc(sizeof(stringNode));	
			curr = head;
		} else {
			curr->next = (stringNode*)
				malloc(sizeof(stringNode));
			curr->next = curr;
		}
		curr->next = NULL;
		curr->data = line;
	}

	return head;
}


int createSocket(void) {
	int socketfd, newsocketfd; 
	struct sockaddr_in addr, cli_addr;
	int clilen, reuseaddr = 1;
	
	if ((socketfd = socket(PF_INET, SOCK_STREAM, 0)) == -1) {
		perror("socket error");
		exit(1);
	}

	addr.sin_addr.s_addr = INADDR_ANY;
	addr.sin_port = htons(7834); // just chose random port :)
	addr.sin_family = PF_INET;
	memset(&(addr.sin_zero), '\0', 8);
	setsockopt(socketfd, SOL_SOCKET, SO_REUSEADDR, 
		&reuseaddr, sizeof(reuseaddr));

	if (bind(socketfd, (struct sockaddr*)&addr, 
		sizeof(struct sockaddr)) == -1) {
		perror("bind");
		exit(1);
	}

	listen(socketfd, 5);

	clilen = sizeof(cli_addr);
	newsocketfd = accept(socketfd, (struct sockaddr *) &cli_addr,
		&clilen);

	fprintf(stderr, "connected!\n");
	shutdown(socketfd, SHUT_RDWR);
	return newsocketfd;
}


void setUpSocketStreams() {
	control->socketfd = createSocket();	
	control->socketRStream = fdopen(control->socketfd, "r");
	control->socketWStream = fdopen(control->socketfd, "w");
	setlinebuf(control->socketRStream);
 	setbuf(control->socketWStream, NULL);
	//fprintf(control->socketWStream, "hello\n");
}


void printVars(stringNode* vars, FILE* outfile) {
	while (vars) {
		fprintf(outfile, "%s\n", vars->data);
		vars = vars->next;
	}
	fprintf(outfile, ".\n");
	fflush(outfile);
}


void minusOne(int* start, int count) {
	int i;
	for (i = 0; i < count; i++) {
		start[i] = -1;
	}
}

/* Creates a gdbControl structure, starts GDB */
void initGDBControl(char ** args) {
	int pid;
	int inpipe[2], outpipe[2];
  
	pipe(inpipe);
	pipe(outpipe);

	pid = fork();
	if (pid > 0) {
		close(inpipe[1]);
		close(outpipe[0]);
		control = (gdbControl*)malloc(sizeof(gdbControl));
		control->gdbInFd = inpipe[0];
		control->gdbOutFd = outpipe[1];
		control->gdbPid = pid;
		control->gdbWStream = fdopen(control->gdbOutFd, "w");
		control->programPid = -1;
		control->programPath = args[GDBARGCOUNT+1];
		control->running = STOPPED;
		control->skipcount = 0;
		control->stopExecAfterWatchpoint = 1;
		control->printDebug = 1;
		control->numStopPoints = 20;
		control->stopPoints = (int*)calloc(control->numStopPoints, 
			sizeof(int));
		
		minusOne(control->stopPoints, 20);
		control->maxStopPoint = 0;
		#ifdef __CYGWIN__
		control->useCygwin = 1;
		control->gdbQueuedCommands = (char*)calloc(2000, sizeof(char));
		control->currentCommandsPos = control->gdbQueuedCommands;
		control->aliases = NULL;
		#else
		control->useCygwin = 0;
		#endif
		sendCommand("set prompt");
	} else if (pid == 0) {
		close(inpipe[0]);
		close(outpipe[1]);
		dup2(inpipe[1], fileno(stdout));
		dup2(inpipe[1], fileno(stderr));
		dup2(outpipe[0], fileno(stdin));
		execvp("gdb", args);
		
		exit(0);
	}
	signal(SIGINT, sigintHandler);
}

/** Extract names of static variables in NesC modules
  * CygWin version - since COFF executables do not have their debugging
  * symbols in a 'human-readable' form, we must actually go back to the
  * source it was compiled from - and get them from build/pc/app.c. 
  * Fortunately this is easy - we just look for 'words' that contain a '$'
  * and have '[1000]', toss away anything after the '[1000]', and if the
  * word begins with a '*', we just get rid of it.
  */
stringNode* cygwinExtractVars(char* program) {
	char* sourceFilename = (char*)malloc((1+strlen(program))*sizeof(char));
	strcpy(sourceFilename, program);

	char* filenameStart = strstr(sourceFilename, "main.exe");
	if (!filenameStart) {   // We don't have main.exe in the filename - so
				// we can't be sure of where to find app.c.
		return NULL;
	}

	strcpy(filenameStart, "app.c");

	int filefd = open(sourceFilename, O_RDONLY);
	if (filefd<0) { // could not open file...
		fprintf(stderr, "Could not open file %s\n", sourceFilename);
		return NULL; 
	}
	
	
	stringNode* head = NULL, * curr = NULL;
	char* line;
	while (line = _read_line(filefd)) {
		char* arrayPos = strstr(line, "[1000]");
		if ((index(line, '$') > line) && strstr(line, "[1000]"))  { 
			// we have a winner!
			arrayPos[0] = '\0';
			char* spacePos = rindex(line, ' ') + 1;
			if (*spacePos == '*')	
				spacePos++;	
			
			char* data = (char*)malloc(sizeof(char) * 
				(1+strlen(spacePos)));
			if (!data) {
				perror("out of mem");
				exit(1);
			}
			strcpy(data, spacePos);
			allocStringNode(&head, &curr, data);		
		}
		free(line);
	}

	fprintf(stderr, "done\n");
	close(filefd);
	free(sourceFilename);
	return head;
}

/** Extract names of static variables in NesC modules 
  * Only returns strings found that have a '$' somewhere after first
  * character.
  *
  * Returns a stringNode list with the strings that were found
  * Returns NULL list if none were found.
  */
stringNode* extractVars(char *program) {
	int pipefds[2];
	int childpid;
	pipe(pipefds);	
	FILE * pipefile;
	char * line = 0;
	size_t len=0;
	ssize_t read;	
	stringNode *head = NULL, *curr = NULL;

	// we're using strings because I'm lazy and it seems ridiculous to
	// write a whole new program when there's already one that can do it!
	childpid = fork();
	switch(childpid) {
		case -1:
			perror("fork");
			exit(1);
		case 0:
			// child
			//close(pipefds[0]);
			dup2(pipefds[1], fileno(stdout));
			execlp("strings", "strings", program, 0);
			exit(1);
		default: 
			// parent
			close(pipefds[1]);
			//pipefile = fdopen(pipefds[0], "r");
	}
	
  	// Had to change this because cygwin doesn't include getline()!
	//while ((read  = getline(&line, &len, pipefile)) != -1) {
	while (line = _read_line(pipefds[0])) {
		// not >= because we don't want lines that start with $, because
		// they'll be garbage
		if (index(line, '$') > line)  { 
			//line[strlen(line) - 1] = 0;
			allocStringNode(&head, &curr, line);
		} else {
			free(line);
		}
		//line = 0;
	}

	return head;
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


void setNonBlocking(int fd, int status) {
	int flags;
	
	if  ((flags = fcntl(fd, F_GETFL, 0)) < 0) {
		perror("F_GETFL error");
	}
	
	if (!status) {
		if (flags & O_NONBLOCK) {
			flags ^= O_NONBLOCK;
		} else return;
	} else {
		flags |= O_NONBLOCK;
	}

	fcntl(fd, F_SETFL, flags);
}


