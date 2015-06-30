// $Id: DTNStubImp.c,v 1.12 2003/10/07 21:46:09 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:  Wei Hong <whong@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */

#include <jni.h>
#include "net_tinyos_util_DTNStub.h"
#include "bundle_api.h"
#include <stdio.h>
#include <errno.h>

#define	REGION					""
#define SENSORPATCH1_URI		"bundles://mule/tcp://10.212.2.120:5000/stuff"
/*
#define DATACENTER_ADMIN	"dcgw"
#define MULE_ADMIN			"dcgw"
*/
#define DEFAULT_LOCALSTUFF	"tinydb"
#define DEFAULT_EXPIRE		60 * 60 * 24 * 3	/* 3 days */

static BUNDLE_AGENT		gBundleAgent;
static BUNDLE_SPEC		gBundleSpec;
static char namebuf1[1024]; /* space for tuple */
static char namebuf2[1024]; /* space for tuple */
static char namebuf3[1024]; /* space for tuple */
static BUNDLE_TUPLE		gLocalTuple = {{0, namebuf1}, 0};
static BUNDLE_TUPLE		gDestTuple1 = {{0, namebuf2}, 0};
static BUNDLE_TUPLE		gDestTuple2 = {{0, namebuf3}, 0};
static BUNDLE_ITERATOR	gBundleIterator = BUNDLE_ITERATOR_NONE;
static uint32_t			gRegCookie = BUNDLE_REG_COOKIE_NONE;
static BUNDLE_SPEC		gBundleSpec1;
static BUNDLE_SPEC		gBundleSpec2;
static int				gPacketSize;
static JNIEnv			*gEnv;
static jobject			gObj;
static jmethodID		gMid;
static jbyteArray		gPacketArray;

extern int (*bundle_arrived_ptr)(BUNDLE_WAITING *);

JNIEXPORT void JNICALL 
Java_net_tinyos_util_DTNStub_openDTNAgent(JNIEnv *env, jobject obj, jstring jBundleAgent)
{
	char *bundleAgentHost = (char*)(*env)->GetStringUTFChars(env, jBundleAgent, 0);
	printf("DTNStubImp: bundleAgentHost = %s\n", bundleAgentHost);
	gBundleAgent = open_agent(bundleAgentHost);
	(*env)->ReleaseStringUTFChars(env, jBundleAgent, bundleAgentHost); 
	if (gBundleAgent != NULL)
		printf("DTNStubImp: open_agent successful.\n");
	else
	{
		printf("DTNStubImp: open_agent failed.\n");
		return;
	}
	if (local_tuple(gBundleAgent, REGION,
							DEFAULT_LOCALSTUFF, &gLocalTuple) < 0)
	{
		printf("DTNStubImp: local_tuple failed.\n");
		return;
	}
	printf("DTNStubImp: local_tuple successful.\n");
	if (remote_tuple(SENSORPATCH1_URI, &gDestTuple1) < 0)
	{
		printf("DTNStubImp: remote_tuple 1 failed.\n");
		return;
	}	
	printf("DTNStubImp: remote_tuple successful.\n");
	if (bundle_spec(COS_NORMAL, COS_NONE, gLocalTuple, gDestTuple1, gLocalTuple, DEFAULT_EXPIRE, &gBundleSpec1) < 0)
		printf("DTNStubImp: bundle_spec 1 failed.\n");
}

JNIEXPORT void JNICALL 
Java_net_tinyos_util_DTNStub_closeDTNAgent(JNIEnv *env, jobject obj)
{
	close_agent(gBundleAgent);
}

int 
receive_bundle(BUNDLE_WAITING *arrive_info)
{
	char bundleFileName[1024];
	jbyte packet[256];
	FILE *fp;
	size_t size;
	memcpy(bundleFileName, arrive_info->filename.filename_val,
			arrive_info->filename.filename_len);
	bundleFileName[arrive_info->filename.filename_len] = '\0';
	printf("DTNStubImp: got a bundle at %s\n", bundleFileName);
	fp = fopen(bundleFileName, "r");
	if (fp == NULL)
	{
		perror("DTNStubImp: unable to open bundle file.");
		return -1;
	}
	size = fread((void*)packet, 1, gPacketSize, fp);
	if (size == 0 && ferror(fp))
	{
		perror("DTNStubImp: fread on bundle failed.");
		return -1;
	}
	printf("DTNStubImp: read %d bytes from bundle\n", size);
	fclose(fp);
	// unlink(bundleFileName);
	if (size > 0)
	{
		(*gEnv)->SetByteArrayRegion(gEnv, gPacketArray, 0, gPacketSize, packet);
		(*gEnv)->CallVoidMethod(gEnv, gObj, gMid, gPacketArray);
		printf("java callback returned.\n");
	}
	return 0;
}

JNIEXPORT void JNICALL 
Java_net_tinyos_util_DTNStub_receiveDTNBundle(JNIEnv *env, jobject obj, jbyteArray jbundle)
{
	jclass cls = (*env)->GetObjectClass(env, obj);
	jfieldID fid = (*env)->GetFieldID(env, cls, "packetSize", "I");
	printf("field id of packetSize is %d\n", fid);
	gEnv = env;
	gObj = obj;
	gMid = (*env)->GetMethodID(env, cls, "packetReceived", "([B)V");
	printf("method id of packetReceived is %d\n", gMid);
	gPacketArray = jbundle;
	gPacketSize = (int)(*env)->GetIntField(env, obj, fid);
	printf("gPacketSize = %d\n", gPacketSize);
	bundle_arrived_ptr = receive_bundle;
	if (demux_register(gBundleAgent, gLocalTuple, BUNDLE_REG_ABORT, &gRegCookie) < 0)
		printf("DTNStubImp: demux_register failed.\n");
	printf("About to call svc_run\n");
	svc_run();
	printf("svc_run returned. errno = %d\n", errno);
}

JNIEXPORT void JNICALL 
Java_net_tinyos_util_DTNStub_sendDTNBundle(JNIEnv *env, jobject obj, jbyteArray jbundle)
{
	// jsize len = (*env)->GetArrayLength(env, jbundle);
	jbyte *bundle = (*env)->GetByteArrayElements(env, jbundle, 0);
	/*
	printf("sending bundle %d bytes", len);
	print_bundle_spec(gBundleSpec1);
	*/
	if (send_bundle_mem(gBundleAgent, gBundleSpec1, (char*)bundle, gPacketSize) < 0)
		printf("DTNStubImp: send_bundle_mem 1 failed.\n");
	/*
	if (send_bundle_mem(gBundleAgent, gBundleSpec2, (char*)bundle, gPacketSize) < 0)
		printf("DTNStubImp: send_bundle_mem 2 failed.\n");
	*/
	(*env)->ReleaseByteArrayElements(env, jbundle, bundle, 0);
}
