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

/*
 * simple quick and dirty program to send and wait for bundles
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>

#define __USE_ISOC99
#include <ctype.h>

#include "bundle_api.h"	/* from libdtn */

char bahost[MAXHOSTNAMELEN] = "localhost";
char bundle_data[2048];
char fname[PATH_MAX];
char localstuff[MAX_TUPLE];
char destTuple[1024];
char sourceIntf[1024] = "";
uint32_t expire = 100; // default time to live (seconds)

uint32_t	theSource = 0;  // 1 = memory; 2 = file; 3 = both
uint32_t	debug = 0;  // higher values cause more info to print
uint32_t	writeResourceFile = 0;
char		sendBuf[2048]; // buffer to send from memory
uint32_t	timesToLoop = 1; //	
uint32_t	pollForResponse = 0;


void usage(char *str1, char *str2);
void readCommandLineArgs(int argc, char **argv);
void readResourceFile();
void writeDefaultsFile(int to_stderr);
static int badline(char *buf);
static int handle_comment(char *buf);
int readLine(FILE *fp, char *buf, int maxSize);

/*
 * note: have to be sort of careful:  underlying XDR routines that
 * deal with character arrays evidently like to scribble in this string's
 * space.  Thus, using string literals can result in SEGV problems when
 * routines like xdr_char attempts to write into the write-protected
 * segment where string literals are stored... (ouch)
 */

// If x==y then set x to z
#define copyIf(x, y, z) if ( strcmp(y, #x ":")==0 ) { strcpy(x, z); }
#define copyIfInt(x, y, z) if ( strcmp(y, #x ":")==0 ) { x = atoi(z); }

int
main(int argc, char **argv)
{
	static char	namebuf[1024];	/* space for tuple */
	static char	namebuf2[1024];	/* space for tuple */
	BUNDLE_AGENT	ba;
	BUNDLE_SPEC	bs;
	BUNDLE_TUPLE	tuple = { { 0, namebuf} , 0 };
	BUNDLE_TUPLE	dst = { { 0, namebuf2}, 0};
	BUNDLE_WAITING	bw;
        BUNDLE_ITERATOR iterator = BUNDLE_ITERATOR_NONE  ;
	uint32_t	reg_cookie = BUNDLE_REG_COOKIE_NONE;
	
	//
	// Read any defaults of out $HOME/.snd_bundlerc
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
	// Sanity check parameters
	//
	if ( theSource==0 ) {
	  usage("snd_bundle", "-s option is required.");
	  exit(EXIT_FAILURE);
	}

	if ( (theSource==2 || theSource==3) && (strlen(fname)==0) ) {
	  usage("snd_bundle", "");
	  fprintf(stderr, "theSource (%d) specifies sending from file\n", theSource);
	  fprintf(stderr, "but no [-f file_name] option given.\n");
	  exit(EXIT_FAILURE);
	}

	//
	// Open connection to bundle agent.
	//
        if ( debug>0 ) {
	  printf("SND BUNDLE:  ***opening bundle agent on host %s\n", bahost);
	}
	if ((ba = open_agent(bahost)) == NULL) {
		fprintf(stderr, "couldn't contact bundle daemon on %s\n", bahost);
		exit(1);
	}
	if ( debug>1 ) {
	  printf("    Bundle agent on host %s open.\n", bahost);
	}

	//
	// Local tuple
	//
	if ( debug>0 ) {
	  printf("snd_bundle: building local tuple with localstuff: '%s'\n",
		 localstuff);
	}
	//
	// If the user specified a source region and source admin part, use those,
	// otherwise call local_tuple which will use one of our regions (the first
	// it finds in the config file) and our hostname.
	//
	if ( strlen(sourceIntf)>0 ) {
	  if ( local_tuple(ba, sourceIntf, localstuff, &tuple) < 0 ) {
	    fprintf(stderr, "trouble building local tuple with source (%s, %s)\n",
		    sourceIntf, localstuff);
	    exit(EXIT_FAILURE);
	  }
	} else {
	  if (local_tuple(ba, NULL, localstuff, &tuple) < 0) {
	    fprintf(stderr, "trouble building tuple with local stuff %s\n", localstuff);
	    exit(EXIT_FAILURE);
	  }
	}
	if ( debug>0 ) {
	  print_tuple(tuple);
	}


	//
	// Destination tuple
	//
	if ( debug>0 ) {
	  printf("snd_bundle: building destination tuple: (%s)\n",
		 destTuple);
	}
	if (remote_tuple(destTuple, &dst) < 0) {
		fprintf(stderr, "trouble building destination tuple\n");
		exit(1);
	}
	if ( debug>0 ) {
	  print_tuple(dst);
	}
	
	// Register the local tuple (dest demux string of inbound bundles)
	// in expectation of receiving responses to what we're going to
	// send.
	if ( pollForResponse ) {
	  if ( debug>0 ) printf("registering tuple...");
	  if (demux_register(ba, tuple, BUNDLE_REG_ABORT, &reg_cookie) < 0) {
	    fprintf(stderr, "trouble registering tuple\n");
	    exit(1);
	  }
	  if ( debug>1 ) printf("ok, cookie was 0x%x\n", reg_cookie);
	}
	
	while ( timesToLoop-->0 ) {
	  //
	  // Send a bundle from memory
	  //
	  if ( theSource==1 || theSource==3 ) {
	    if ( debug>0 ) {
	      printf("sending bundle from memory...\n");
	    }
	    /* build a bundle spec */
	    if (bundle_spec(COS_NORMAL, COS_NONE, tuple, dst, tuple, expire, &bs) < 0) {
	      fprintf(stderr, "trouble building bundle_spec\n");
	      exit(1);
	    }
	    /* send the bundle with the spec */
	    if (send_bundle_mem(ba, bs, bundle_data, strlen(bundle_data)) < 0) {
	      fprintf(stderr, "trouble sending bundle from memory\n");
	      exit(1);
	    }
	  }
	
	  //
	  // Send a bundle from a file
	  //
	  if ( theSource==2 || theSource==3 ) {
	    if ( debug>0 ) {
	      printf("sending bundle from file...\n");
	    }
	    if (bundle_spec(COS_NORMAL, COS_NONE, tuple, dst, tuple, expire, &bs) < 0) {
	      fprintf(stderr, "trouble building bundle_spec\n");
	      exit(EXIT_FAILURE);
	    }
	    if (send_bundle_file(ba, bs, fname) < 0) {
	      fprintf(stderr, "trouble sending bundle from file '%s'\n", fname);
	      exit(EXIT_FAILURE);
	    }
	  }
	}

	//
	// If we were looking for a response, here's how to poll
	//
	if ( pollForResponse ) {
	  if ( debug>0 ) printf("Sleeping for a bit...\n");
	  sleep(15);
	  if ( debug>0 ) {
	    printf("polling for tuple:\n");
	    print_tuple(tuple);
	  }

	  while (bundle_poll(ba, tuple, &iterator, &bw) == BUNDLE_SUCCESS) {
	    printf("yup, got a bundle at %s\n", bw.filename.filename_val);
	    printf("with bundle spec:\n");
	    print_bundle_spec(bw.bs);
	  }
	  printf("no more incoming bundles...\n");
	  printf("unregistering tuple...\n");
	  if (demux_register_cancel(ba, reg_cookie) < 0) {
	    fprintf(stderr, "trouble unregistering tuple\n");
	    exit(1);
	  }
	}

	if ( debug>0 ) {
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

  while ((c=getopt(argc, argv, "b:l:D:I:e:s:m:f:n:d:pwh"))!=EOF) {
    switch(c) {
    case 'b': // bundle agent host
      strcpy(bahost, optarg);
      break;
    case 'l':
      strcpy(localstuff, optarg);
      break;
    case 'D': // destination region
      strcpy(destTuple, optarg);
      break;
    case 'I': // source interface
      strcpy(sourceIntf, optarg);
      break;
    case 'e': // expire
      expire = atoi(optarg);
      break;
    case 's': // source: 1=memory, 2=file, 3=both
      theSource = atoi(optarg);
      break;
    case 'm': // string to send from memory
      strcpy(bundle_data, optarg);
      break;
    case 'f': // file to send, only makes sense for source=2 or 3
      strcpy(fname, optarg);
      break;
    case 'w':
      writeResourceFile = 1;
      break;
    case 'h':
      usage("snd_bundle", "");
      exit(0);
      break;
    case 'n':
      timesToLoop = atoi(optarg);
      break;
    case 'p':
      pollForResponse = 1;
      break;
    case 'd':
      debug = atoi(optarg);
      break;
    default:
      fprintf(stderr, "snd_bundle: unknown option: '%c'\n", (char) c);
      usage("snd_bundle", "");
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
  strcat(resourceFileName, "/.snd_bundlerc");
  fp = fopen(resourceFileName, "r");
  if ( fp==NULL ) {
    ;
  } else {
    while ( 1 ) {
      memset(inputBuf, 0, INBUFSIZE);
      numRead = readLine(fp, inputBuf, INBUFSIZE);
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
      copyIf(sourceIntf, theLine[0], theLine[1]);
      copyIf(localstuff, theLine[0], theLine[1]);
      copyIf(destTuple, theLine[0], theLine[1]);
      copyIfInt(theSource, theLine[0], theLine[1]);
      copyIf(bundle_data, theLine[0], theLine[1]);
      copyIf(fname, theLine[0], theLine[1]);
      copyIfInt(expire, theLine[0], theLine[1]);
      copyIfInt(pollForResponse, theLine[0], theLine[1]);
      copyIfInt(timesToLoop, theLine[0], theLine[1]);
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
    strcat(resourceFileName, ".snd_bundlerc");
    fp = fopen(resourceFileName, "w");
  }
  if ( fp==NULL ) {
    fprintf(stderr, "snd_bundle: can't open resource file '%s' for writing.\n",
	   resourceFileName);
    return;
  }
  fprintf(fp, "# snd_bundlerc\n#\n");
  fprintf(fp, "# This file was generaged as the result of a\n");
  fprintf(fp, "#   '-w' argument to snd_bundle.  Future uses of\n");
  fprintf(fp, "#   '-w' will overwrite this file.\n#\n");
  fprintf(fp, "bahost: %s\n", bahost);
  fprintf(fp, "bundle_data: %s\n", bundle_data);
  fprintf(fp, "fname: %s\n", fname);
  fprintf(fp, "sourceIntf: %s\n", sourceIntf);
  fprintf(fp, "localstuff: %s\n", localstuff);
  fprintf(fp, "destTuple: %s\n", destTuple);
  fprintf(fp, "expire: %d\n", expire);
  fprintf(fp, "pollForResponse: %d\n", pollForResponse);
  fprintf(fp, "theSource: %d\n", theSource);
  fprintf(fp, "debug: %d\n", debug);
  if ( to_stderr ) {
  } else {
    fclose(fp);
  }
}


void
usage(char *str1, char *str2)
{
  fprintf(stderr, "usage: %s\n", str1);
  fprintf(stderr, "  [-b bundleAgent]  - specify host name where bundle agent is running.\n");
  fprintf(stderr, "  [-I source-intf-matchstr]  - sending intf matching string\n");
  fprintf(stderr, "  [-l localStuff]   - localstuff at source\n");
  fprintf(stderr, "  [-D dest]   - destination tuple\n");
  fprintf(stderr, "  [-e expire]       - set expiration (delta seconds from now).\n");
  fprintf(stderr, "  -s bundlePayloadSource - 1: send from memory\n");
  fprintf(stderr, "                           2: send from file.\n");
  fprintf(stderr, "                           3: send from memory and file.\n");
  fprintf(stderr, "  [-m data-string]       - string to send when sending\n");
  fprintf(stderr, "                      from memory.\n");
  fprintf(stderr, "  [-f fileToSend]   - file to send when sending files.\n");
  fprintf(stderr, "  [-n timesToLoop]  - number of (identical) bundles to send\n");
  fprintf(stderr, "                      (2n bundles if bundlePayloadSource is 3).\n");
  fprintf(stderr, "  [-p]              - poll for responses instead of using\n");
  fprintf(stderr, "                      async callbacks.\n");
  fprintf(stderr, "  [-w]              - write current arguments to\n");
  fprintf(stderr, "                      $HOME/.snd_bundle\n");
  fprintf(stderr, "  [-d debugValue]\n");
  fprintf(stderr, "  [-h]              - print this message.\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "    %s\n", str2);
}

static int
badline(char *buf)
{
  while (isblank(*buf))
    buf++;
  if (*buf == '\n' || *buf == '#' || *buf == '\r')
    return (1); /* bad line */
  return (0);	/* useful line */
}

static int
handle_comment(char *buf)
{
  char *p = strchr(buf, '#');
  if (p != NULL) {
    /* kill of spaces before # */
    while ((p > buf) && isblank(p[-1]))
      --p;
    *p = '\0';
    return (p - buf);
  }
  return (-1);
}

int
readLine(FILE *fp, char *buf, int maxSize)
{
  char *p;
  int n;

  while (1) {
    if (fgets(buf, maxSize, fp) == NULL)
      return 0;
    if (badline(buf))
      continue;
    else if ((n = handle_comment(buf)) > 0)
      return (n);
    break;
  }

  p = strchr(buf, '\n');
  *p = '\0';
  return (p - buf);
}

