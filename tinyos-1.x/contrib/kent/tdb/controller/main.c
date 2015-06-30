#include "gdbcontrol.h"
#include <stdlib.h>
#include <stdarg.h>
#include <signal.h>

int main(int argc, char ** argv) {
	if (argc < 3) {
		fprintf(stderr, "Usage: %s [program] [arguments]\n\n"
			"\tprogram: \tthe TinyOS executable (main.exe)\n"
			"\targuments:\tthe arguments to the TinyOS program\n",
			argv[0]);
		exit(1);
	}

	char ** args = makeArgs(argc, argv);

	initGDBControl(args);
	makeCommandString(argc, argv);
	startRunning();
	setUpSocketStreams();	
	eventLoop();
	
	return 0;
}

void sendToSocket(const char* line, ...) {
	va_list ap;
	va_start(ap, line);
	vfprintf(control->socketWStream, line, ap);
	fflush(control->socketWStream);
	va_end(ap);
}

void sendToGdb(const char* line, ...) {
	va_list ap;
	va_start(ap, line);
	vfprintf(control->gdbWStream, line, ap);
	fflush(control->gdbWStream);
	va_end(ap);
}


void pauseExecution() {
	if (control->running == RUNNING && control->programPid > -1) {
		kill(control->programPid, SIGINT);
		control->running = PAUSED;
	}
}
		

