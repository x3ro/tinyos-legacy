/*
 * Copyright (c) 2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * Utility routines for parsing NVT
 *
 * Author:  Andrew Christian <andrew.christian@hp.com>
 *          14 March 2005
 */

#ifndef __NVTPARSE_H
#define __NVTPARSE_H

/* saves 1KB in Menu app by not inlining these functions */
#define nvtinline 

/*****************************************
 *  Helper functions
 *****************************************/

nvtinline char * mark_line( char *buf, char *buf_max )
{
  int state;
  
  for ( state = 0 ;  buf < buf_max ; buf++ ) {
    switch (state) {
    case 0:
      if (*buf == '\r')
	state = 1;
      break;
    case 1:
      if (*buf == '\n') {
	*(buf-1) = 0;  // Mark the previous '\r' 
	return buf + 1;
      }
      state = 0;
      break;
    }
  }
    
  // End of buffer
  *(buf - 1) = 0;   // Kill the last character to null terminate
  return buf_max;   // The 'next' pointer will hit the maximum
}

nvtinline char *next_token( char *in, char **next, char sep )
{
  char *p;

  // Skip whitespace
  while (*in == ' ')
    in++;

  if (*in == 0)
    return NULL;

  // Scan ahead to separator
  p = in + 1;
  while ( *p != 0 && *p != sep)
    p++;

  if (*p == sep) {
    *p = 0;  // Null Terminate
    *next = p + 1;  // Here's the next token
  }
  else {
    *next = p;   // It's a null
  }

  return in;  // Return the token
}

nvtinline char *skip_white( char *in )
{
  // Skip whitespace
  while (*in == ' ')
    in++;

  return in;
}

  // Shamelessly modified from atoi in gcc-libc
nvtinline uint16_t atou( const char *p )
{
  uint16_t res = 0;

  while( *p==' '
	 || *p=='\t'
	 || *p=='\n'
	 || *p=='\f'
	 || *p=='\r'
	 || *p=='\v' ) p++;

  if(!isdigit(*p)) return 0;

  while(1)
    {
      res += *p - '0';
      p++;
      if(!isdigit(*p)) break;
      res = res*10;
    }
  return res;
}

  // Shamelessly modified from atoi in gcc-libc
nvtinline uint32_t atoul( const char *p )
{
  uint32_t res = 0;

  while( *p==' '
	 || *p=='\t'
	 || *p=='\n'
	 || *p=='\f'
	 || *p=='\r'
	 || *p=='\v' ) p++;

  if(!isdigit(*p)) return 0;

  while(1)
    {
      res += *p - '0';
      p++;
      if(!isdigit(*p)) break;
      res = res*10;
    }
  return res;
}


#endif
