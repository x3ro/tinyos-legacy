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
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include "bundle_api.h"

char bahost[MAXHOSTNAMELEN] = "localhost";
char scriptName[8192] = "";
char localstuff[1024] = "";
uint32_t	reg_cookie = BUNDLE_REG_COOKIE_NONE;

uint8_t parseTuple(char *routing, char *admin, int *adminlen, char *t);
void usage(char *str1, char *str2);
void readCommandLineArgs(int argc, char **argv);
void readResourceFile();
void writeDefaultsFile(int to_stderr);
uint32_t writeResourceFile = 0;
uint32_t debug = 0;
char matchstr[1024] = "";

extern int (*bundle_arrived_ptr)(BUNDLE_WAITING *);

// If x==y then set x to z
#define copyIf(x, y, z) if ( strcmp(y, #x ":")==0 ) { strcpy(x, z); }
#define copyIfInt(x, y, z) if ( strcmp(y, #x ":")==0 ) { x = atoi(z); }



//struct BUNDLE_SPEC {
//  BUNDLE_COS cos;
//  BUNDLE_DELIVERY_OPTS dopts;
//  BUNDLE_TUPLE source;
//  BUNDLE_TUPLE dest;
//  BUNDLE_TUPLE reply_to;
//  int32_t expire;
//};
int receive_bundle(BUNDLE_WAITING *arrive_info)
{
  char buff[1024];
  int retVal;
  static int count = 0;
  char *bundleFileName;
  char sourceRegion[1024];
  char sourceAdmin[1024];
  int sourceAdminLength;
  char destRegion[1024];
  char destAdmin[1024];
  int destAdminLength;
  struct stat statBuf;

  parseTuple(sourceRegion, sourceAdmin, &sourceAdminLength,
	     (char *) &(arrive_info->bs.source));
  parseTuple(destRegion, destAdmin, &destAdminLength,
	     (char *) &(arrive_info->bs.dest));
  bundleFileName = arrive_info->filename.filename_val;
  bundleFileName[arrive_info->filename.filename_len] = '\0';
  stat(bundleFileName, &statBuf);
  printf("Received file[%d]: %s, %d bytes long\n", 
	 ++count, bundleFileName, (int) statBuf.st_size);
  if ( strlen(scriptName)>0 ) {
    sprintf(buff, "%s %s\n", scriptName, bundleFileName);
    retVal = system(buff);
  }
  return(0);
}


/*
* note: have to be sort of careful:  underlying XDR routines that
* deal with character arrays evidently like to scribble in this string's
* space.  Thus, using string literals can result in SEGV problems when
* routines like xdr_char attempts to write into the write-protected
* segment where string literals are stored... (ouch)
*/

int
main(int argc, char **argv)
{
  static char	namebuf[1024];	/* space for tuple */
  BUNDLE_AGENT	ba;
  BUNDLE_TUPLE	tuple = { { 0, namebuf} , 0 };
  int ret;


  //
  // Read any defaults of out $HOME/.async_rcvrrc
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
    usage("async_rcvr", "bahost required");
    exit(-1);
  }
  if ( strlen(localstuff)==0 ) {
    usage("async_rcvr", "localstuff required.\n");
    exit(-1);
  }


  if ( debug>0 ) {
    printf("***opening bundle agent on host %s\n", bahost);
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
  if ( debug>0 ) print_tuple(tuple);

  // Tell the api what our incoming bundle routine is
  bundle_arrived_ptr = receive_bundle;

  if ( debug>0 ) printf("registering tuple...");
  if ((ret = demux_register(ba, tuple, BUNDLE_REG_DEFER, &reg_cookie)) != BUNDLE_SUCCESS) {
    fprintf(stderr, "trouble registering tuple (demux_register returned %d\n", ret);
    exit(1);
  }
  if ( debug>0 ) printf("ok, cookie was 0x%x\n", reg_cookie);

  if (writeResourceFile)
  	writeDefaultsFile(0); // 0 -> write to file, not stderr

  svc_run();
  perror("svc_run() returned");
  exit(1);
}


uint8_t
parseTuple(char *routing, char *admin, int *adminlen, char *t)
{
  __uint8_t tupleSize;
  int i;
  tupleSize = t[0];
  strcpy(routing, &(t[1]));
  i = 2 + strlen(routing);
  memcpy(admin, &(t[i]), tupleSize - i);
  if (adminlen)
    *adminlen = tupleSize - i;
#if 0
  i += strlen(admin) + 1;
  stringSize = strlen(routing)+1+strlen(admin)+1;
  if ( instanceID!=NULL ) {
    memcpy(&temp, &(t[stringSize+1]), sizeof(int));
    *instanceID = ntohl(temp);
  }
#endif
  return(tupleSize);
}

void
readCommandLineArgs(int argc, char **argv)
{
  int c;

  while ((c=getopt(argc, argv, "b:r:a:c:s:d:hwe:"))!=EOF) {
    switch(c) {
    case 'b':
      strcpy(bahost, optarg);
      break;
    case 'c':
      reg_cookie = atoi(optarg);
      break;
    case 's': // demux string
      strcpy(localstuff, optarg);
      break;
    case 'a':
      strcpy(matchstr, optarg);
      break;
    case 'd': // debug
      debug = atoi(optarg);
      break;
    case 'h': // 
      usage("async_rcvr", "");
      exit(0);
      break;
    case 'e': // execute script on received bundle file
      strcpy(scriptName, optarg);
      break;
    case 'w': // save to resource file
      writeResourceFile = 1;
      break;
    default:
      fprintf(stderr, "async_rcvr: unknown option: '%c'\n", (char) c);
      usage("async_rcvr", "");
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
  strcat(resourceFileName, "/.async_rcvrrc");
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
      copyIfInt(reg_cookie, theLine[0], theLine[1]);
      copyIf(localstuff, theLine[0], theLine[1]);
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
    strcat(resourceFileName, ".async_rcvrrc");
    fp = fopen(resourceFileName, "w");
  }
  if ( fp==NULL ) {
    fprintf(stderr, "async_rcvr: can't open resource file '%s' for writing.\n",
	   resourceFileName);
    return;
  }
  fprintf(fp, "# async_rcvrrc\n#\n");
  fprintf(fp, "# This file was generaged as the result of a\n");
  fprintf(fp, "#   '-w' argument.  Future uses of\n");
  fprintf(fp, "#   '-w' will overwrite this file.\n#\n");
  fprintf(fp, "bahost: %s\n", bahost);
  fprintf(fp, "localstuff: %s\n", localstuff);
  fprintf(fp, "reg_cookie: %d\n", reg_cookie);
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
  fprintf(stderr, "[-c reg_cookie] ");
  fprintf(stderr, "[-s localstuff] ");
  fprintf(stderr, "[-a src-matchstr] ");
  fprintf(stderr, "[-d debugValue] ");
  fprintf(stderr, "[-w ] ");
  fprintf(stderr, "[-h] ");
  fprintf(stderr, "[-e script] ");
  fprintf(stderr, "\n");
  fprintf(stderr, "    %s\n", str2);
}
