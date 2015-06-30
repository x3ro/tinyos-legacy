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

#include "bundle_common.h"

#define	rpcvers_t	unsigned long

/*
 * open_agent / close_agent open and close the RPC connection with a
 * particular bundle agent (the hostname of which is given as the
 * argument to open_agent().
 */
extern BUNDLE_AGENT open_agent(char* bundleAgentHost);
extern void close_agent(BUNDLE_AGENT agent);

/*
 * open_app / close_app are the peers to open/close_agent for the
 * other direction of the bundleDaemon <--> application connection.
 * That is, open_app / clos_app are called by the bundle daemon to
 * establish / release an RPC connection to a bundle aware
 * application.  
 */
extern BUNDLE_APP open_app(char* host, rpcvers_t vers);
extern void close_app(BUNDLE_AGENT agent);

/*
 * The demux_register[_XXXX] functions are used by bundle applications
 * to tell the bundle daemon that the application is interested in
 * certain bundles.  The bundles that application wants to receive are
 * those matching the 'BUNDLE_TUPLE' argument.
 *
 * demux_register_cancel() removes a registration.
 */
extern int demux_register(BUNDLE_AGENT, BUNDLE_TUPLE, BUNDLE_REG_ACTION, uint32_t *);
extern int demux_register_exec(BUNDLE_AGENT, BUNDLE_TUPLE, char*, int, uint32_t *);
extern int demux_register_cancel(BUNDLE_AGENT, uint32_t);

int local_tuple(BUNDLE_AGENT, char *intfname_pattern, char *localstuff, BUNDLE_TUPLE *);
void print_tuple(BUNDLE_TUPLE);
extern int send_bundle_mem(BUNDLE_AGENT, BUNDLE_SPEC, char*, int);
extern int send_bundle_file(BUNDLE_AGENT, BUNDLE_SPEC, char*);
extern int deliver_bundle_file(BUNDLE_APP, BUNDLE_SPEC, char*);
extern int bundle_spec(BUNDLE_COS cos,
			BUNDLE_DELIVERY_OPTS dopts,
			BUNDLE_TUPLE src,
			BUNDLE_TUPLE dst,
			BUNDLE_TUPLE reply,
			int32_t expire, BUNDLE_SPEC *bs);
extern int remote_tuple(char*uri, BUNDLE_TUPLE *);
extern int bundle_poll(BUNDLE_AGENT, BUNDLE_TUPLE, BUNDLE_ITERATOR *, BUNDLE_WAITING *);
extern void print_bundle_spec(BUNDLE_SPEC);
extern int local_region(char *, int);
extern int bundle_readline(FILE*, char*, int);
extern int bundle_readline_simple(FILE*, char*, int);
extern char *bundle_str(char *, int);
