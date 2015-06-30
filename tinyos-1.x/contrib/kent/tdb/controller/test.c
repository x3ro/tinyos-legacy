#include "gdbcontrol.h"
#include <stdarg.h>

char buf[2000];
char* currBufPos = buf;

char gdbBuf[2000];
char* currGdbPos = gdbBuf;

int isKilled;

/*void Assert(char* text, int cond) {
	if (!cond) 
		printf("%s FAILED\n", text);
	else printf(".");
}

void AssertFalse(char* text, int cond) {
	Assert(text, !cond);
}*/

#ifdef __CYGWIN__
#define __STRING(x) "x"
#endif

#define AssertReason(str, expr) \
	((expr) ? 0 : \
		(printf("FAILED: %s, %s %d %s: %s\n", str, __FILE__, __LINE__,\
			__FUNCTION__,  __STRING(expr))))
#define AssertFalseReason(str, expr) \
	((expr) ? \
		(printf("FAILED: %s, %s %d %s: %s\n", str, __FILE__, __LINE__,\
			__FUNCTION__, __STRING(expr)))\
		: 0)
#define AssertEqualsReason(str, arg1, arg2) \
	((arg1) == (arg2) ? 0 : \
		(printf("FAILED: %s, %s %d %s: expected %d, got %d\n", str,\
			__FILE__, __LINE__, __FUNCTION__, arg1, arg2)))
#define AssertNotEqualsReason(str, arg1, arg2) \
	((arg1) != (arg2) ? 0 : \
		(printf("FAILED: %s, %s %d %s: expected anything but %d, got %d\n", str,\
			__FILE__, __LINE__, __FUNCTION__, arg1, arg2)))
#define AssertStrEqualsReason(str, arg1, arg2) \
	((!strcmp((arg1),(arg2))) ? 0 : \
		(printf("FAILED: %s, %s %d %s: expected '%s', got '%s'\n", str,\
			__FILE__, __LINE__, __FUNCTION__, arg1, arg2)))

#define Assert(expr) \
	((expr) ? 0 : \
		(printf("FAILED: %s %d %s: %s\n",  __FILE__, __LINE__,\
			__FUNCTION__,  __STRING(expr))))
#define AssertFalse(expr) \
	((expr) ? \
		(printf("FAILED: %s %d %s: %s\n",  __FILE__, __LINE__,\
			__FUNCTION__, __STRING(expr)))\
		: 0)

void setupControl() {
	control->programPid = 234;
	control->socketfd = 2;
	control->gdbInFd = -1;
	control->gdbOutFd = 2;
	control->state = NORMAL;
	control->gdbWStream = NULL;		
	control->socketWStream = NULL;		
	control->socketRStream = NULL;		
	control->programPath = "/tmp/foo";
	control->running = RUNNING;
	control->skipcount = 0;	
	control->stopExecAfterWatchpoint = 1;
	control->printDebug = 0;
	control->command = "run 30";
	control->numStopPoints = 20;
	control->stopPoints = 
		(int*)calloc(control->numStopPoints, sizeof(int));
	minusOne(control->stopPoints, 20);
	control->maxStopPoint = 0;
	bzero(buf, 2000);
	bzero(gdbBuf, 2000);
	control->gdbQueuedCommands = (char*) calloc(2000, sizeof(char));
	control->currentCommandsPos = control->gdbQueuedCommands;
	bzero(control->gdbQueuedCommands, 2000);
	currBufPos = buf;
	currGdbPos = gdbBuf;
	isKilled = 0;
	control->useCygwin = 0;
	control->aliases = 0;
}

void testStartup() {
	setupControl();
	control->programPid = -1;	

	handleGdbInput("(gdb) Starting program: /tmp/foo 3 >/dev/null");
	Assert(control->state & GETPID);
	handleGdbInput("[New Thread 1074126976 (LWP 10415)]");
	Assert(control->programPid == 10415);
	Assert(control->skipcount == 2);
	handleGdbInput("[New Thread 1074184976 (LWP 10416)]");
	Assert(control->skipcount == 1);
	handleGdbInput("[New Thread 1009238976 (LWP 10417)]");
	Assert(control->skipcount == 0);
	Assert(control->state == NORMAL);

	setupControl();
	control->programPid = -1;
	startRunning();
	AssertStrEqualsReason("Should send proper commands",
		"set environment DBG=\nset prompt\nset width 400\ndisplay tos_state.current_node\nrun 30\n", gdbBuf);
}

void testStoppedMessages() {
	setupControl();
	handleGdbInput("Program received signal SIGINT, Interrupt.");
	handleGdbInput("0x0804a630 in swap (first=0x1, second=0x1) at heap_array.c:159");
	handleGdbInput("159   }");
	handleGdbInput("1: tos_state.current_node = 2");
	AssertReason("Should not write anything", strlen(buf)==0);
	Assert(control->state == NORMAL);
	
	setupControl();
	handleGdbInput("Program received signal SIGINT, Interrupt.");
	AssertEqualsReason("Should be STOPPEDMSGS", STOPPEDMSGS, control->state);
	handleGdbInput("ChannelMonC$event_channel_mon_handle (fevent=0x82c6128, state=0x82b4ae0)");
	handleGdbInput("    at ChannelMonC.nc:155");
	handleGdbInput("155         event_queue_t* queue = &(state->queue);");
	handleGdbInput("1: tos_state.current_node = 2");
	AssertEqualsReason("Should not write anything", strlen(buf), 0);
	AssertEqualsReason("State should be NORMAL", NORMAL, control->state);

	setupControl();
	handleGdbInput("Program received signal SIGINT, Interrupt.");
	handleGdbInput("0x40055a96 in pthread_mutex_lock () from /lib/tls/libpthread.so.0");
	handleGdbInput("1: tos_state.current_node = 2");
	handleGdbInput("$1 = 3");
	AssertStrEqualsReason("Must contain input", "$1 = 3\n", buf);	
	AssertEqualsReason("State should be NORMAL", NORMAL, control->state);

	setupControl();
	handleGdbInput("Program received signal SIGINT, Interrupt.");
	handleGdbInput("0xffffe002 in ?? ()");
	handleGdbInput("1: tos_state.current_node = 2");
	AssertEqualsReason("Should not write anything", 0, strlen(buf));
	AssertEqualsReason("State should be NORMAL", NORMAL, control->state);

	setupControl();
	handleGdbInput("Program received signal SIGINT, Interrupt.");
	handleGdbInput("0x08049119 in dbg_active (mode=0) at dbg.h:81");
	handleGdbInput("81      return (dbg_modes & mode) != 0;");
	handleGdbInput("1: tos_state.current_node = 2");
	AssertEqualsReason("Should not write anything", 0, strlen(buf));
	AssertEqualsReason("State should be NORMAL", NORMAL, control->state);

}	

void testWatchpoint() {
	setupControl();
	control->maxStopPoint = 1;
	handleGdbInput("Hardware watchpoint 2: SurgeM$timer_ticks[2]");
	AssertEqualsReason("Should not write anything", 0, strlen(buf));
	AssertEqualsReason("State should be NORMAL", NORMAL, control->state);
	handleGdbInput("Hardware watchpoint 2: SurgeM$timer_ticks[2]");
	AssertEqualsReason("Should be WATCHPOINT|FIRSTLINE", WATCHPOINT|FIRSTLINE, control->state);
	handleGdbInput("");
	handleGdbInput("Old value = 0");
	handleGdbInput("New value = 1");
	handleGdbInput("SurgeM$Timer$fired () at SurgeM.nc:122");
	handleGdbInput("122           call ADC.getData();");
	handleGdbInput("1: tos_state.current_node = 2");
	AssertEqualsReason("State should be NORMAL", NORMAL, control->state);
	AssertEqualsReason("Should be 2", 2, control->maxStopPoint);
	AssertStrEqualsReason("Should inform of status",
		"Hardware watchpoint 2: SurgeM$timer_ticks[2] was 0, now 1\n"
		"SurgeM$Timer$fired () at SurgeM.nc:122\n"
		"122           call ADC.getData();\n", buf);
	
}

void testWatchPause() {
	//AssertReason("Not yet written", 0);
	setupControl();
	control->stopExecAfterWatchpoint = 1;
	handleGdbInput("Hardware watchpoint 2: SurgeM$timer_ticks[2]");
	handleGdbInput("Hardware watchpoint 2: SurgeM$timer_ticks[2]");
	handleGdbInput("");
	handleGdbInput("Old value = 0");
	handleGdbInput("New value = 1");
	handleGdbInput("SurgeM$Timer$fired () at SurgeM.nc:122");
	handleGdbInput("122           call ADC.getData();");
	AssertEqualsReason("Should be paused, so we can continue",
		PAUSED, control->running);
	
	setupControl();
	control->stopExecAfterWatchpoint = 0;
	handleGdbInput("Hardware watchpoint 2: SurgeM$timer_ticks[2]");
	AssertStrEqualsReason("Should be info breakpoints",
		"info breakpoints\ncontinue\n", gdbBuf);
	currGdbPos = gdbBuf;
	gdbBuf[0] = '\0';
	handleGdbInput("Hardware watchpoint 2: SurgeM$timer_ticks[2]");
	handleGdbInput("");
	handleGdbInput("Old value = 0");
	handleGdbInput("New value = 1");
	handleGdbInput("SurgeM$Timer$fired () at SurgeM.nc:122");
	handleGdbInput("122           call ADC.getData();");
	AssertEqualsReason("Should be running",
		RUNNING, control->running);
	AssertStrEqualsReason("Should be continue", "continue\n", gdbBuf);
	
	
}

void testSources() {
	setupControl();
	handleGdbInput("Source files for which symbols have been read in:");
	AssertEqualsReason("Should be GETSOURCES", GETSOURCES, control->state);
	AssertStrEqualsReason("Should send SENDING SOURCES", 
		"SENDING SOURCES\n", buf);
	handleGdbInput("");
	AssertEqualsReason("Should be GETSOURCES", GETSOURCES, control->state);
	handleGdbInput("../sysdeps/i386/elf/start.S, init.c,");
	handleGdbInput("/usr/src/build/324954-i386/BUILD/glibc-2.3.2-200304020432/build-i386-linux/csu/crti.S, build/pc/app.c, hardware.h, Nido.nc, dbg.h, external_comm.c, BareSendMsg.nc, ReceiveMsg.nc, AMPromiscuous.nc, MultiHopLEPSM.nc, BcastM.nc,");
	AssertEqualsReason("Should be GETSOURCES", GETSOURCES, control->state);
	handleGdbInput("nido.h");
	AssertEqualsReason("Should be GETSOURCES", GETSOURCES, control->state);
	handleGdbInput("");
	handleGdbInput("Source files for which symbols will be read in on demand:");
	AssertEqualsReason("Should be NORMAL", NORMAL, control->state);
	handleGdbInput("");
	AssertEqualsReason("Should be NORMAL", NORMAL, control->state);
	AssertStrEqualsReason("Should send list of sources", 
		"SENDING SOURCES\n"
		"init.c\nbuild/pc/app.c\nhardware.h\nNido.nc\ndbg.h\n"
		"external_comm.c\nBareSendMsg.nc\nReceiveMsg.nc\n"
		"AMPromiscuous.nc\nMultiHopLEPSM.nc\nBcastM.nc\nnido.h\n.\n",
		buf);

	setupControl();
	control->useCygwin = 1;
	handleGdbInput("Source files for which symbols have been read in:");
	AssertEqualsReason("Should be GETSOURCES", GETSOURCES, control->state);
	AssertStrEqualsReason("Should send SENDING SOURCES", 
		"SENDING SOURCES\n", buf);
	handleGdbInput("");
	AssertEqualsReason("Should be GETSOURCES", GETSOURCES, control->state);
	handleGdbInput("../sysdeps/i386/elf/start.S, init.c,");
	handleGdbInput("/usr/src/build/324954-i386/BUILD/glibc-2.3.2-200304020432/build-i386-linux/csu/crti.S, build/pc/app.c, hardware.h, Nido.nc, dbg.h, external_comm.c, BareSendMsg.nc, ReceiveMsg.nc, AMPromiscuous.nc, MultiHopLEPSM.nc, BcastM.nc,");
	AssertEqualsReason("Should be GETSOURCES", GETSOURCES, control->state);
	handleGdbInput("nido.h");
	AssertEqualsReason("Should be GETSOURCES", GETSOURCES, control->state);
	handleGdbInput("");
	handleGdbInput("Source files for which symbols will be read in on demand:");
	AssertEqualsReason("Should be NORMAL", NORMAL, control->state);
	handleGdbInput("");
	AssertEqualsReason("Should be NORMAL", NORMAL, control->state);
	AssertStrEqualsReason("Should send list of sources", 
		"SENDING SOURCES\n"
		"init.c\nbuild/pc/app.c\nhardware.h\nNido.nc\ndbg.h\n"
		"external_comm.c\nBareSendMsg.nc\nReceiveMsg.nc\n"
		"AMPromiscuous.nc\nMultiHopLEPSM.nc\nBcastM.nc\nnido.h\n.\n",
		buf);
}
	

void testCygwinStartup() {
	setupControl();
	control->useCygwin = 1;
	control->programPid = -1;

	handleGdbInput("Breakpoint 1 at 0x405c7d: file C:/cygwin/opt/tinyos-1.x/tos/platform/pc/sched.c, line 144.");
	handleGdbInput("Starting program: /tmp/foo 30");
	handleGdbInput("\n");
	handleGdbInput("Breakpoint 1, TOSH_run_next_task () at C:/cygwin/opt/tinyos-1.x/tos/platform/pc/sched.c:144");
	handleGdbInput("144       if (TOSH_sched_full == TOSH_sched_free) {");
	handleGdbInput("1: tos_state.current_node = 2");
	handleGdbInput("       Using the running image of child thread 716.0x7a8.");
	handleGdbInput("Program stopped at 0x405c7d.");
	handleGdbInput("It stopped at breakpoint 1.");
	AssertEqualsReason("Get proper PID", 716, control->programPid);
	AssertEqualsReason("Should be NORMAL", NORMAL, control->state);
	AssertEqualsReason("Should be 0", 0, control->skipcount);
	AssertEqualsReason("Should be 1", 1, control->maxStopPoint);
	AssertStrEqualsReason("Should be empty", "", buf);

	setupControl();
	control->useCygwin = 1;
	control->programPid = -1;
	startRunning();
	AssertStrEqualsReason("Must send proper commands",
		"set environment DBG=\nset prompt\nset width 400\ndisplay tos_state.current_node\nbreak TOSH_run_next_task\nrun 30\n"
		"info program\ncontinue\n",
		gdbBuf);
	AssertEqualsReason("should be RUNNING", RUNNING, control->running);
	AssertEqualsReason("should be 1", 1, control->skipcount);
} 

void testSendCommand() {
	setupControl();
	control->useCygwin = 0;
	control->running = RUNNING;

	sendCommand("help");
	AssertStrEqualsReason("should have continue", 
			"help\ncontinue\n", 
			gdbBuf);
	AssertEqualsReason("Should be killed", 1, isKilled);

	setupControl();
	control->useCygwin = 1;
	
	sendCommand("help");
	AssertStrEqualsReason("Should be empty", "", gdbBuf);
	AssertStrEqualsReason("should be help", "help\n", 
		control->gdbQueuedCommands);
	AssertEqualsReason("Should not be killed", 0, isKilled);

	setupControl();
	control->useCygwin = 1;
	control->running = PAUSED;
	sendCommand("continue");
	AssertStrEqualsReason("Should have stuff", "continue\n", gdbBuf);
	AssertStrEqualsReason("should be empty", "", 
		control->gdbQueuedCommands);
	AssertEqualsReason("Should not be killed", 0, isKilled);
	
}

void testCygwinMainBreakpoint() {
	setupControl();
	control->useCygwin = 1;
	handleGdbInput("Breakpoint 1, TOSH_run_next_task () at C:/cygwin/opt/tinyos-1.x/tos/platform/pc/sched.c:144");
	handleGdbInput("144       if (TOSH_sched_full == TOSH_sched_free) {");
	handleGdbInput("1: tos_state.current_node = 1");
	AssertStrEqualsReason("Should continue", "ignore 1 1000\ncontinue\n", gdbBuf);
	AssertStrEqualsReason("No output", "", buf);
	AssertEqualsReason("Should not skip!", 0, control->skipcount);

	setupControl();
	control->useCygwin = 1;
	sendCommand("foObAR");
	handleGdbInput("Breakpoint 1, TOSH_run_next_task () at C:/cygwin/opt/tinyos-1.x/tos/platform/pc/sched.c:144");
	handleGdbInput("144       if (TOSH_sched_full == TOSH_sched_free) {");
	handleGdbInput("1: tos_state.current_node = 3");
	AssertStrEqualsReason("command, then continue", "foObAR\nignore 1 1000\ncontinue\n",
		gdbBuf);
	AssertStrEqualsReason("No waiting commands", "", control->gdbQueuedCommands);
	AssertStrEqualsReason("No output", "", buf);
	AssertEqualsReason("Should not skip!", 0, control->skipcount);

	setupControl();
	control->useCygwin = 1;
	handleGdbInput("Continuing.");
	AssertStrEqualsReason("No output", "", buf);
	
	setupControl();
	control->useCygwin = 1;
	handleGdbInput("Will ignore next 2 crossings of breakpoint 1.");
	handleGdbInput("Continuing.");
	AssertStrEqualsReason("No output", "", buf);
	handleGdbInput("$0 = 0 '\\0'");
	AssertStrEqualsReason("Should output", "$0 = 0 '\\0'\n", buf);
	AssertEqualsReason("Should not skip!", 0, control->skipcount);
	
	setupControl();
	breakpointNode foo;
	foo.breakpointNum = 10;
	foo.child = 0;
	foo.next = 0;
	control->aliases = &foo;
	control->useCygwin = 1;
	control->stopPoints[10] = -1;
	handleGdbInput("Breakpoint 10, TOSH_run_next_task () at C:/cygwin/opt/tinyos-1.x/tos/platform/pc/sched.c:144");
	handleGdbInput("144       if (TOSH_sched_full == TOSH_sched_free) {");
	handleGdbInput("1: tos_state.current_node = 3");
	AssertStrEqualsReason("Should not continue",  "", gdbBuf);
	AssertFalse(strlen(buf) == 0);
}

void testDeletePoint() {
	setupControl();
	control->useCygwin = 0;
	handleSocketInput("delete 1");
	AssertStrEqualsReason("Should send", "delete 1\ncontinue\n", gdbBuf);

	setupControl();
	control->useCygwin = 0;
	handleSocketInput("delete 10");
	AssertStrEqualsReason("Should send", "delete 10\ncontinue\n", gdbBuf);

	setupControl();
	control->useCygwin = 1;
	handleSocketInput("delete 10");
	AssertStrEqualsReason("Should send", "delete 10\n", 
		control->gdbQueuedCommands);

	setupControl();
	control->useCygwin = 1;
	handleSocketInput("delete 1");
	AssertStrEqualsReason("Should not send", "", 
		control->gdbQueuedCommands);
}

void testBreakpoint() {
	setupControl();
	control->maxStopPoint = 2;
	handleGdbInput("Breakpoint 3 at 0x0804c49f: file SurgeM.nc, line 30.");
	AssertStrEqualsReason("Should not say anything", "", buf);
	AssertStrEqualsReason("Should request info", "info breakpoints\ncontinue\n", 
		gdbBuf);
	AssertEqualsReason("Should be 3", 3, control->maxStopPoint);
	currGdbPos = gdbBuf;
	gdbBuf[0] = 0;

	breakpointNode foo;
	foo.breakpointNum = 3;
	foo.child = 0;
	foo.next = 0;
	control->aliases = &foo;

	handleGdbInput("Breakpoint 3, SurgeM$initialize () at SurgeM.nc:77");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 6");
	AssertStrEqualsReason("Should output", 
		"Breakpoint 3, SurgeM$initialize () at SurgeM.nc:77\n"
		"            timer_rate = INITIAL_TIMER_RATE;\nCurrentMote 6\n",
		buf);
	AssertStrEqualsReason("Should not send anything", "", gdbBuf);
	AssertEqualsReason("Should be PAUSED", PAUSED, control->running);	
	currBufPos = buf;
	handleGdbInput("123         unsigned long long max_run_time = 0;");
	handleGdbInput("1: tos_state.current_node = 6");
	AssertStrEqualsReason("Should output", 
		"123         unsigned long long max_run_time = 0;\n",
		buf);
	currBufPos = buf;
	buf[0] = '\0';
	handleGdbInput("0x0804b0b5 in TimerM$Timer$fired (arg_0x89b9410=1 '\001') at Timer.nc:73");
	handleGdbInput("73      event result_t fired();");
	AssertStrEqualsReason("Should output",
		"0x0804b0b5 in TimerM$Timer$fired (arg_0x89b9410=1 '\001') at Timer.nc:73\n"
		"73      event result_t fired();\n",
		buf);
	handleGdbInput("Continuing.");
	AssertEqualsReason("Should be RUNNING", RUNNING, control->running);
}

void testBreakWatchInfo() {
	setupControl();
	control->useCygwin = 1;
	handleGdbInput("Num Type           Disp Enb Address    What");
	AssertStrEqualsReason("Should be SENDING BREAKPOINTS", 
		"SENDING BREAKPOINTS\n", buf);
	currBufPos = buf;
	buf[0] = '\0';
	handleGdbInput("1   breakpoint     keep y   0x0804f1ce in TOSH_run_next_task at sched.c:144");
	AssertStrEqualsReason("Should be empty", "", buf);
	handleGdbInput("        breakpoint already hit 2 times");
	handleGdbInput("2   breakpoint     keep y   0x0804b675 in SurgeM$Timer$fired at SurgeM.nc:122");
	AssertStrEqualsReason("Should send", 
		"2   breakpoint     keep y   0x0804b675 in SurgeM$Timer$fired at SurgeM.nc:122\n", buf);
	handleGdbInput("3   hw watchpoint  keep y              tos_state.current_node");
	currBufPos = buf;
	buf[0] = '\0';
	handleGdbInput("Will ignore next 999 crossings of breakpoint 1.");
	handleGdbInput("Continuing.");
	AssertStrEqualsReason("Should send finish", ".\n", buf);

	setupControl();
	control->useCygwin = 0;
	control->stopPoints[1] = -1;
	control->stopPoints[2] = 2;
	handleGdbInput("Num Type           Disp Enb Address    What");
	handleGdbInput("1   breakpoint     keep y   0x0804f1ce in TOSH_run_next_task at sched.c:144");
	handleGdbInput("        breakpoint already hit 1 time");
	handleGdbInput("2   breakpoint     keep y   0x0804b675 in SurgeM$Timer$fired at SurgeM.nc:122");
	handleGdbInput("3   hw watchpoint  keep y              tos_state.current_node");
	handleGdbInput("        breakpoint already hit 2 times");
	handleGdbInput("Continuing.");
	AssertStrEqualsReason("Should send proper stuff",
		"SENDING BREAKPOINTS\n"
		"1   breakpoint     keep y   0x0804f1ce in TOSH_run_next_task at sched.c:144\n"	
		"2   breakpoint     keep y   0x0804b675 in SurgeM$Timer$fired at SurgeM.nc:122\n"	
		"MOTE 2\n"
		"3   hw watchpoint  keep y              tos_state.current_node\n.\n",
		 buf);

	setupControl();
	control->useCygwin = 1;
	handleGdbInput("Num Type           Disp Enb Address    What");
	AssertStrEqualsReason("Should be SENDING BREAKPOINTS", 
		"SENDING BREAKPOINTS\n", buf);
	currBufPos = buf;
	buf[0] = '\0';
	handleGdbInput("1   breakpoint     keep y   0x0804f1ce in TOSH_run_next_task at sched.c:144");
	AssertStrEqualsReason("Should be empty", "", buf);
	handleGdbInput("        breakpoint already hit 38002 times");
	handleGdbInput("Asdf");
	AssertStrEqualsReason("Should send finish", ".\nAsdf\n", buf);

	setupControl();
	handleGdbInput("No breakpoints or watchpoints.");
	AssertStrEqualsReason("Send blank list", "SENDING BREAKPOINTS\n.\n",
		buf);

}

void testToggleContinue() {
	setupControl();
	control->stopExecAfterWatchpoint = 0;
	handleSocketInput("togglecontinue");
	AssertStrEqualsReason("should send", "STOPMODE\n", buf);
	currBufPos = buf;
	buf[0] = '\0';
	handleSocketInput("togglecontinue");
	AssertStrEqualsReason("should send", "CONTMODE\n", buf);
}

void testTooManyWatchpoints() {
	setupControl();
	handleGdbInput("warning: Could not remove hardware watchpoint 5.");
	handleGdbInput("Warning:");
	handleGdbInput("Could not insert hardware watchpoint 5.");
	handleGdbInput("Could not insert hardware breakpoints:");
	handleGdbInput("You may have requested too many hardware breakpoints/watchpoints.");
	AssertStrEqualsReason("Should be silent", "", buf);
	AssertStrEqualsReason("Should give commands",
		"disable 5\ninfo breakpoints\ncontinue\n", gdbBuf);
}

void testInitMoteBreakpoint() {
	setupControl();
	control->maxStopPoint = 2;
	handleSocketInput("MOTE 15");
	AssertEqualsReason("Did not set mote number properly", 15, 
		control->stopPoints[3]);
	
}

void testMoteBreakpoint() {
	setupControl();
	control->stopPoints[3] = 3;
	
	breakpointNode foo;
	foo.breakpointNum = 3;
	foo.child = 0;
	foo.next = 0;
	control->aliases = &foo;

	handleGdbInput("Breakpoint 3, SurgeM$initialize () at SurgeM.nc:77");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 6");
	handleGdbInput("Continuing.");
	AssertStrEqualsReason("Should skip this breakpoint", "continue\n", gdbBuf);
	AssertEqualsReason("Should be RUNNING", RUNNING, control->running);	
	AssertStrEqualsReason("Should send nothing", "", buf);

	buf[0] = 0;
	currBufPos = buf;
	gdbBuf[0] = 0;
	currGdbPos = gdbBuf;
	handleGdbInput("Breakpoint 3, SurgeM$initialize () at SurgeM.nc:77");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 3");
	AssertStrEqualsReason("Should output", 
		"Breakpoint 3, SurgeM$initialize () at SurgeM.nc:77\n"
		"            timer_rate = INITIAL_TIMER_RATE;\nCurrentMote 3\n",
		buf);
	AssertStrEqualsReason("Should send nothing", "", gdbBuf);
	AssertEqualsReason("Should be PAUSED", PAUSED, control->running);	
}

void testDisabledBreakpointAliases() {
	setupControl();
	handleGdbInput("Num Type           Disp Enb Address    What");
	handleGdbInput("1   breakpoint     keep n   0x0804b675 in SurgeM$Timer$fired at SurgeM.nc:122");
	handleGdbInput("2   breakpoint     keep y   0x0804b675 in SurgeM$Timer$fired at SurgeM.nc:122");
	handleGdbInput("Continuing.");

	AssertNotEqualsReason("Should be different", getBreakpointAliases(1),
		getBreakpointAliases(2));
	AssertEqualsReason("Should give null", 0, 
		getBreakpointAliases(1));

	buf[0] = 0;
	currBufPos = buf;
	gdbBuf[0] = 0;
	currGdbPos = gdbBuf;

	control->stopPoints[1] = 1;
	control->stopPoints[2] = 2;

	handleGdbInput("Breakpoint 2, SurgeM$initialize () at SurgeM.nc:122");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 1");
	AssertStrEqualsReason("Should not output", "", buf);
	handleGdbInput("Continuing.");
	AssertStrEqualsReason("Should skip this breakpoint", "continue\n", gdbBuf);
	AssertEqualsReason("Should be RUNNING", RUNNING, control->running);	
	AssertStrEqualsReason("Should send nothing", "", buf);
	
	buf[0] = 0;
	currBufPos = buf;
	gdbBuf[0] = 0;
	currGdbPos = gdbBuf;

	handleGdbInput("Breakpoint 2, SurgeM$initialize () at SurgeM.nc:122");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 2");
	AssertStrEqualsReason("Should output", 
		"Breakpoint 2, SurgeM$initialize () at SurgeM.nc:122\n"
		"            timer_rate = INITIAL_TIMER_RATE;\nCurrentMote 2\n",
		buf);
	AssertStrEqualsReason("Should send nothing", "", gdbBuf);
	AssertEqualsReason("Should be PAUSED", PAUSED, control->running);		
	handleGdbInput("Continuing.");
	AssertEqualsReason("Should be RUNNING", RUNNING, control->running);	

	buf[0] = 0;
	currBufPos = buf;
	gdbBuf[0] = 0;
	currGdbPos = gdbBuf;


	handleGdbInput("Breakpoint 2, SurgeM$initialize () at SurgeM.nc:122");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 4");
	AssertStrEqualsReason("Should not output", "", buf);
	handleGdbInput("Continuing.");
	AssertStrEqualsReason("Should skip this breakpoint", "continue\n", gdbBuf);
	AssertEqualsReason("Should be RUNNING", RUNNING, control->running);	
	AssertStrEqualsReason("Should send nothing", "", buf);
}

void testBreakpointAliases() {
	setupControl();
	handleGdbInput("Num Type           Disp Enb Address    What");
	handleGdbInput("1   breakpoint     keep y   0x0804b675 in SurgeM$Timer$fired at SurgeM.nc:122");
	handleGdbInput("2   breakpoint     keep y   0x0804b675 in SurgeM$Timer$fired at SurgeM.nc:122");
	handleGdbInput("3   breakpoint     keep y   0x0804b375 in SurgeM$Timer$fired at SurgeM.nc:125");
	handleGdbInput("4   hw watchpoint  keep y              tos_state.current_node");
	handleGdbInput("Continuing.");

	AssertEqualsReason("Should give the same list", 
		getBreakpointAliases(1), getBreakpointAliases(2));
	AssertNotEqualsReason("Should not be null", 0,
		getBreakpointAliases(1));
	AssertNotEqualsReason("Should be different", getBreakpointAliases(1),
		getBreakpointAliases(3));
	AssertEqualsReason("Should give null", 0, 
		getBreakpointAliases(4));
	AssertNotEqualsReason("Must be different!", control->aliases, control->aliases->child);
	AssertNotEqualsReason("Must be different!", control->aliases, control->aliases->child->child);
	AssertEqualsReason("Must be null", NULL, control->aliases->child->child);

	buf[0] = 0;
	currBufPos = buf;
	gdbBuf[0] = 0;
	currGdbPos = gdbBuf;

	control->stopPoints[1] = 2;
	control->stopPoints[2] = 1;

	handleGdbInput("Breakpoint 1, SurgeM$initialize () at SurgeM.nc:122");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 1");
	AssertStrEqualsReason("Should output", 
		"Breakpoint 1, SurgeM$initialize () at SurgeM.nc:122\n"
		"            timer_rate = INITIAL_TIMER_RATE;\nCurrentMote 1\n",
		buf);
	AssertStrEqualsReason("Should send nothing", "", gdbBuf);
	AssertEqualsReason("Should be PAUSED", PAUSED, control->running);		
	handleGdbInput("Continuing.");
	AssertEqualsReason("Should be RUNNING", RUNNING, control->running);	
	
	buf[0] = 0;
	currBufPos = buf;
	gdbBuf[0] = 0;
	currGdbPos = gdbBuf;

	handleGdbInput("Breakpoint 1, SurgeM$initialize () at SurgeM.nc:122");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 2");
	AssertStrEqualsReason("Should output", 
		"Breakpoint 1, SurgeM$initialize () at SurgeM.nc:122\n"
		"            timer_rate = INITIAL_TIMER_RATE;\nCurrentMote 2\n",
		buf);
	AssertStrEqualsReason("Should send nothing", "", gdbBuf);
	AssertEqualsReason("Should be PAUSED", PAUSED, control->running);		
	handleGdbInput("Continuing.");
	AssertEqualsReason("Should be RUNNING", RUNNING, control->running);	

	buf[0] = 0;
	currBufPos = buf;
	gdbBuf[0] = 0;
	currGdbPos = gdbBuf;


	handleGdbInput("Breakpoint 1, SurgeM$initialize () at SurgeM.nc:122");
	handleGdbInput("            timer_rate = INITIAL_TIMER_RATE;");
	handleGdbInput("1: tos_state.current_node = 4");
	AssertStrEqualsReason("Should not output", "", buf);
	handleGdbInput("Continuing.");
	AssertStrEqualsReason("Should skip this breakpoint", "continue\n", gdbBuf);
	AssertEqualsReason("Should be RUNNING", RUNNING, control->running);	
	AssertStrEqualsReason("Should send nothing", "", buf);
}

void testGetAliasAttachPoint() {
	setupControl();
	AssertEqualsReason("Should be &aliases", &(control->aliases),
		getAliasAttachPoint(0x40502345));
	breakpointNode node;
	node.address = 0x40502345;
	node.child = NULL;
	node.next = NULL;
	control->aliases = &node;
	AssertEqualsReason("Should be node->child", &(node.child), 
		getAliasAttachPoint(0x40502345));
	breakpointNode node2 ;
	node2.address = 0x40502345;
	node2.child = NULL;
	node2.next = NULL;
	node.child = &node2;
	AssertEqualsReason("Should be node2->child", &(node2.child), 
		getAliasAttachPoint(0x40502345));
	AssertEqualsReason("Should be node->next", &(node.next),
		getAliasAttachPoint(0x12345678));
	breakpointNode node3;
	node3.address = 0x98764321;
	node3.child = NULL;
	node3.next = NULL;
	node.next = &node3;
	AssertEqualsReason("Should be node3->child", &(node3.child),
		getAliasAttachPoint(0x98764321));
	AssertEqualsReason("Should be node3->next", &(node3.next),
		getAliasAttachPoint(0xFFFFFFFF));
}

void testFreeBreakpointAliases() {
	setupControl();
	breakpointNode* node = (breakpointNode*)malloc(sizeof(breakpointNode));
	node->child = (breakpointNode*)malloc(sizeof(breakpointNode));
	node->child->child = (breakpointNode*)malloc(sizeof(breakpointNode));
	node->child->next = NULL;
	node->child->child->next = NULL;
	node->child->child->child = NULL;
	node->next = (breakpointNode*)malloc(sizeof(breakpointNode));
	node->next->next = NULL;
	node->next->child = (breakpointNode*)malloc(sizeof(breakpointNode));
	node->next->child->child = NULL;
	node->next->child->next = NULL;
	control->aliases = node;	

	freeBreakpointAliases();
	AssertEqualsReason("Must be null!", NULL, control->aliases);
}

int main(void) {
	control = (gdbControl*)malloc(sizeof(gdbControl));

	testStartup();
	testStoppedMessages();
	testWatchpoint();
	testWatchPause();
	testSources();
	testCygwinStartup();
	testSendCommand();
	testCygwinMainBreakpoint();
	testDeletePoint();
	testBreakpoint();
	testBreakWatchInfo();
	testToggleContinue();
	testTooManyWatchpoints();
	testInitMoteBreakpoint();
	testMoteBreakpoint();
	testBreakpointAliases();
	testGetAliasAttachPoint();
	testDisabledBreakpointAliases();
	testFreeBreakpointAliases();

	return 0;
}

void sendToSocket(const char* line, ...) {
	va_list ap;
	va_start(ap, line);
	currBufPos += vsprintf(currBufPos, line, ap);
	va_end(ap);
}

void sendToGdb(const char* line, ...) {
	va_list ap;
	va_start(ap, line);
	currGdbPos += vsprintf(currGdbPos, line, ap);
	va_end(ap);
}

void pauseExecution() {
	if (control->running == RUNNING && control->programPid > -1) {
		isKilled = 1;
		control->running = PAUSED;
	}
}

