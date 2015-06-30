/*
 * IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 * By downloading, copying, installing or using the software you agree to this
 * license.  If you do not agree to this license, do not download, install,
 * copy or use the software.
 * 
 * Intel Open Source License 
 * 
 * Copyright (c) 1996-2003 Intel Corporation. All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 	Redistributions of source code must retain the above copyright notice,
 * 	this list of conditions and the following disclaimer. 
 * 
 * 	Redistributions in binary form must reproduce the above copyright
 * 	notice, this list of conditions and the following disclaimer in the
 * 	documentation and/or other materials provided with the distribution. 
 * 
 * 	Neither the name of the Intel Corporation nor the names of its
 * 	contributors may be used to endorse or promote products derived from
 * 	this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include "bundle_api.h"

char bahost[MAXHOSTNAMELEN] = "localhost";
char demuxString[1024] = "";
char localstuff[1024] = "";
char matchstr[1024] = "";
BUNDLE_ITERATOR iterator = BUNDLE_ITERATOR_NONE;
int debug = 0;

void usage(char *str1, char *str2);
void readCommandLineArgs(int argc, char **argv);
void readResourceFile();
void writeDefaultsFile(int to_stderr);
int writeResourceFile = 0;
int timesToPoll = 10;

// If x==y then set x to z
#define copyIf(x, y, z) if ( strcmp(y, #x ":")==0 ) { strcpy(x, z); }
#define copyIfInt(x, y, z) if ( strcmp(y, #x ":")==0 ) { x = atoi(z); }


/*
 * note: have to be sort of careful:  underlying XDR routines that
 * deal with character arrays evidently like to scribble in this string's
 * space.  Thus, using string literals can result in SEGV problems when
 * routines like xdr_char attempts to write into the write-protected
 * segment where string literals are stored... (ouch)
 */

int
main(int argc, char** argv)
{
	static char	namebuf[1024];	/* space for tuple */
	BUNDLE_AGENT	ba;
	BUNDLE_TUPLE	tuple = { { 0, namebuf} , 0 };
	BUNDLE_WAITING	bw;
	int first_time = 1;

	int 		c, ret;
        int 		received_bundle_count = 0;


	//
	// Read any defaults of out $HOME/.polling_rcvrrc
	// 
	readResourceFile();

	//
	// Read off the command arguments
	//
	readCommandLineArgs(argc, argv);

	if ( debug>4 ) {
	  writeDefaultsFile(1); // Write to stderr
	}

	//
	// Sanity check arguments
	//
	if ( strlen(bahost)==0 ) {
	  usage("polling_rcvr", "bundleAgent required");
	  exit(-1);
	}
	if ( strlen(demuxString)==0 ) {
	  usage("polling_rcvr", "demuxString required.\n");
	  exit(-1);
	}

	//
	// Open connection to bundle agent.
	//
	if ( debug>0) {
	  printf("polling_rcvr: ***opening bundle agent on host %s\n", bahost);
	}
	if ((ba = open_agent(bahost)) == NULL) {
		fprintf(stderr, "couldn't contact bundle daemon on %s\n", bahost);
		exit(1);
	}
	if ( debug>1 ) {
	  printf("    Bundle agent open.\n");
	}

	/* API doesn't do mem alloc for us; we must do it */
	if ( strlen(matchstr)>0 ) {
	  	if ( debug>0 ) printf("creating local tuple with name...\n");
		if (local_tuple(ba, matchstr, localstuff, &tuple) < 0) {
			fprintf(stderr, "trouble building tuple with source matchstr %s\n",
					matchstr);
			exit(1);
	        }
	} else {
	        if ( debug>0 ) printf("creating local tuple...\n");
		if (local_tuple(ba, NULL, localstuff, &tuple) < 0) {
			fprintf(stderr, "trouble building tuple with localstuff %s\n", localstuff);
			exit(1);
		}
	}

	if ( debug>0 ) {
	  print_tuple(tuple);
	}

	if ( debug>0 ) {
	  printf("polling for tuple:\n");
	  print_tuple(tuple);
	}

	for (c = 0; c < timesToPoll; c++ ) {
	     if ((ret =
		bundle_poll(ba, tuple, &iterator, &bw)) == BUNDLE_SUCCESS) {
		if (first_time == 1) {
		  if ( debug>0 ) printf("Bundle poll iterator set to %d\n", iterator);
		  first_time = 0;
		}
		received_bundle_count++;
		if ( debug>0 ) {
		  printf("yup, got a bundle[%d] at %s\n", 
			 received_bundle_count, bw.filename.filename_val);
		  //printf("with bundle spec:\n");
		  //print_bundle_spec(bw.bs);
		  //printf("and iterator 0x%x\n", iterator);
		}
	     } else { 
		if (first_time == 1) {
		  if ( debug>0 ) printf("Bundle poll iterator set to %d\n", iterator);
		  first_time = 0;
		}
		if ( debug>0 ) {
		  printf(".");
		  fflush(stdout);
		}
		sleep(1);
	     }

	}
	if ( debug>0 ) {
	  printf("I'm tired of waiting for bundles...\n");
	  printf("\n***all done (success)\n");
	}
	close_agent(ba);
	
	if ( writeResourceFile ) {
	  writeDefaultsFile(0);
	}
	exit(0);
}

void
readCommandLineArgs(int argc, char **argv)
{
  int c;

  while ((c=getopt(argc, argv, "b:s:i:n:d:hw"))!=EOF) {
    switch(c) {
    case 'b':
      strcpy(bahost, optarg);
      break;
    case 'i': // bundle agent host
      iterator = atoi(optarg);
      break;
    case 's': // demux string
      strcpy(demuxString, optarg);
      break;
    case 'n': // timesToPoll
      	timesToPoll = atoi(optarg);
	break;
    case 'd': // debug
      debug = atoi(optarg);
      break;
    case 'h': // 
      usage("pollingReceiver", "");
      exit(0);
      break;
    case 'w': // save to resource file
      writeResourceFile = 1;
      break;
    default:
      fprintf(stderr, "polling_rcvr: unknown option: '%c'\n", (char) c);
      usage("polling_rcvr", "");
      exit(-1);
    }
  }
}

void
readResourceFile()
{
#define INBUFSIZE 2048

  FILE *fp = NULL;
  char resourceFileName[1024];
  char inputBuf[INBUFSIZE];
  char theLine[20][1024];
  int  i;
  char *ptr;
  char *next;
  uint32_t	numRead;

  strcpy(resourceFileName, getenv("HOME"));
  strcat(resourceFileName, "/.polling_rcvrrc");
  fp = fopen(resourceFileName, "r");
  if ( fp==NULL ) {
    ;
  } else {
    while ( 1 ) {
      memset(inputBuf, 0, INBUFSIZE);
      numRead = bundle_readline(fp, inputBuf, INBUFSIZE);
      if ( numRead==0 ) break;
      ptr = inputBuf;
      i = 0;
      while ( 1 ) {
	next = strtok(ptr, " \t\n");
	if ( next==NULL ) break;
	strcpy(theLine[i++], next);
	ptr = NULL;
      } 
      if ( i!=2 ) {
	continue;
      }
      copyIf(bahost, theLine[0], theLine[1]);
      copyIf(demuxString, theLine[0], theLine[1]);
      copyIfInt(iterator, theLine[0], theLine[1]);
      copyIfInt(debug, theLine[0], theLine[1]);
    }
    fclose(fp);
  }
}

void
writeDefaultsFile(int to_stderr)
{
  FILE *fp;
  char resourceFileName[1024];
  if ( to_stderr ) {
    fp = stderr;
  } else {
    strcpy(resourceFileName, getenv("HOME"));
    strcat(resourceFileName, "/");
    strcat(resourceFileName, ".polling_rcvrrc");
    fp = fopen(resourceFileName, "w");
  }
  if ( fp==NULL ) {
    fprintf(stderr, "polling_rcvr: can't open resource file '%s' for writing.\n",
	   resourceFileName);
    return;
  }
  fprintf(fp, "# polling_rcvrrc\n#\n");
  fprintf(fp, "# This file was generaged as the result of a\n");
  fprintf(fp, "#   '-w' argument to polling_rcvr.  Future uses of\n");
  fprintf(fp, "#   '-w' will overwrite this file.\n#\n");
  fprintf(fp, "bahost: %s\n", bahost);
  fprintf(fp, "demuxString: %s\n", demuxString);
  fprintf(fp, "iterator: %d\n", iterator);
  fprintf(fp, "debug: %d\n", debug);
  if ( to_stderr ) {
  } else {
    fclose(fp);
  }
}

void
usage(char *str1, char *str2)
{
  fprintf(stderr, "usage: %s ", str1);
  fprintf(stderr, "[-b bundleAgent] ");
  fprintf(stderr, "[-i bundleIterator] ");
  fprintf(stderr, "[-s demuxString] \n    ");
  fprintf(stderr, "[-d debugValue] ");
  fprintf(stderr, "[-n timesToPoll] ");
  fprintf(stderr, "[-w ] ");
  fprintf(stderr, "[-h] ");
  fprintf(stderr, "\n");
  fprintf(stderr, "    %s\n", str2);
}
