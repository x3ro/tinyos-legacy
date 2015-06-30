/*  JNI methods for interfacing TOSSIM with Ptolemy II

 Copyright (c) 2005-2006 The Regents of the University of California.
 All rights reserved.
 Permission is hereby granted, without written agreement and without
 license or royalty fees, to use, copy, modify, and distribute this
 software and its documentation for any purpose, provided that the above
 copyright notice and the following two paragraphs appear in all copies
 of this software.

 IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY
 FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
 THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
 PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 ENHANCEMENTS, OR MODIFICATIONS.

 PT_COPYRIGHT_VERSION_2
 COPYRIGHTENDKEY

 */

/*
 *
 * Authors:             Elaine Cheong
 *
 */

#include <jni.h>

// Begin from tinyos-1.x/contrib/ptII/ptinyos/tos/types/AM.h ==============
#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 29
#endif

typedef struct TOS_Msg
{
  /* The following fields are transmitted/received on the radio. */
  unsigned short /*uint16_t*/ addr;
  unsigned char  /*uint8_t*/ type;
  unsigned char  /*uint8_t*/ group;
  unsigned char  /*uint8_t*/ length;
  signed char /*int8_t*/ data[TOSH_DATA_LENGTH];
  unsigned short /*uint16_t*/ crc;

  /* The following fields are not actually transmitted or received 
   * on the radio! They are used for internal accounting only.
   * The reason they are in this structure is that the AM interface
   * requires them to be part of the TOS_Msg that is passed to
   * send/receive operations.
   */
  unsigned short /*uint16_t*/ strength;
  unsigned char  /*uint8_t*/ ack;
  unsigned short /*uint16_t*/ time;
  unsigned char  /*uint8_t*/ sendSecurityMode;
  unsigned char  /*uint8_t*/ receiveSecurityMode;  
} TOS_Msg;

typedef TOS_Msg *TOS_MsgPtr;
// End from tinyos-1.x/contrib/ptII/ptinyos/tos/types/AM.h ==============

void ptII_receive_packet(long long ptolemyTime, const char *packet);

// End from tinyos-1.x/contrib/ptII/ptinyos/tos/types/dbg_modes.h
typedef long long TOS_dbg_mode;

JavaVM *ptII_vm = NULL;                 // The original calling Java VM.
jobject ptII_global_obj;                // The original calling Java object.

JNIEnv *ptII_JNIEnv_env;                // The calling Java environment.
jobject ptII_jobject_obj;               // The calling Java object.

// Methods in the calling Java object's class.
jmethodID ptII_jmethodID_enqueueEvent;
jmethodID ptII_jmethodID_tosDebug;
jmethodID ptII_jmethodID_getCharParameterValue;
jmethodID ptII_jmethodID_sendToPort;
jmethodID ptII_jmethodID_joinThreads;
jmethodID ptII_jmethodID_startThreads;

// Socket methods in the calling Java object's class.
jmethodID ptII_jmethodID_serverSocketCreate;
jmethodID ptII_jmethodID_serverSocketClose;
jmethodID ptII_jmethodID_selectorCreate;
jmethodID ptII_jmethodID_selectorRegister;
jmethodID ptII_jmethodID_selectorClose;
jmethodID ptII_jmethodID_selectSocket;
jmethodID ptII_jmethodID_acceptConnection;
jmethodID ptII_jmethodID_socketChannelClose;
jmethodID ptII_jmethodID_socketChannelWrite;
jmethodID ptII_jmethodID_socketChannelRead;

// Mutex methods in the Object class in Java.
jmethodID ptII_jmethodID_Object_notify;
jmethodID ptII_jmethodID_Object_notifyAll;
jmethodID ptII_jmethodID_Object_wait;

// Methods defined in pre-existing TOSSIM files in this directory.
// ptII_fire() is defined in:
// - tinyos-1.x/contrib/ptII/ptinyos/beta/TOSSIM-packet/Nido.nc
// - tinyos-1.x/contrib/ptII/ptinyos/tos/platform/ptII/Nido.nc
extern void ptII_fire(long long ptolemyTime);
// ptII_insert_packet_event() is defined in:
// - tinyos-1.x/contrib/ptII/ptinyos/beta/TOSSIM-packet/packet_sim.c
extern void ptII_insert_packet_event(long long ptolemyTime, TOS_MsgPtr msg);
// eventAcceptThreadFunc() and commandReadThreadFunc() are defined in:
// - tinyos-1.x/contrib/ptII/ptinyos/tos/platform/ptII/external_comm.c:
extern void *eventAcceptThreadFunc(void *arg);
extern void *commandReadThreadFunc(void *arg);

// Name mangling for name space separation with other nodes.
#define PTII_NATIVE_METHOD_CONCAT(funcname, postfix) Java_Loader##postfix##funcname##postfix
#define PTII_NATIVE_METHOD(funcname, postfix, params) \
 PTII_NATIVE_METHOD_CONCAT(funcname, postfix) params

// Array for storing error messages when generating a Throwable to
// pass to Java.
#define ERROR_MESSAGE_SIZE 500
char ERROR_MESSAGE[ERROR_MESSAGE_SIZE];

/* Utility function that throws a named exception.  Finds the
   exception class and then issues a call to the ThrowNew function.
   Arguments:
     env: Java environment
     name: name (including path) of exception class
     msg: error message
 */
 void JNU_ThrowByName(JNIEnv *env, const char *name, const char *msg) {
     jclass cls = (*env)->FindClass(env, name);
     // if cls is NULL, an exception has already been thrown
     if (cls != NULL) {
         (*env)->ThrowNew(env, cls, msg);
     }
     // free the local ref
     (*env)->DeleteLocalRef(env, cls);
 }

/* Native method called from Java.
   Set up argc and argv to call main() of TOSSIM.
   Arguments:
     jobjectArray: conntains an array of java String's
       for the arguments to main().
   Returns: 0 on success, -1 on error.
*/
JNIEXPORT jint JNICALL PTII_NATIVE_METHOD(_main, _PTII_NODE_NAME, (JNIEnv *env, jobject obj, jobjectArray argsToMain)) {
    // Store calling environment.
    ptII_JNIEnv_env = env;

    // Store calling object (java).
    if ((ptII_global_obj = (*env)->NewGlobalRef(env, obj)) == NULL) {
        // NewGlobalRef() returns a global reference. The result is NULL
        // if the system runs out of memory, if the given argument is
        // NULL, or if the given reference is a weak global reference
        // referring to an object that has already been garbage
        // collected.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to NewGlobalRef() returned NULL.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return -1; 
    }

    // Store calling JVM.
    if ((*env)->GetJavaVM(env, &ptII_vm) < 0) {
        // GetJavaVM() returns zero on success; otherwise, returns a
        // negative value. Returns a negative number if and only if an
        // invocation of this function has thrown an exception.

        // Handle Throwable in calling Java code.
        return -1;
    }
    
    // Get class of calling object.
    jclass cls;
    // GetObjectClass() does not result in any exceptions, so don't
    // check for any.
    cls = (*env)->GetObjectClass(env, obj);

    // Store handle to enqueueEvent() method in Java.
    ptII_jmethodID_enqueueEvent = (*env)->GetMethodID(env, cls, "enqueueEvent", "(Ljava/lang/String;)V");
    if (ptII_jmethodID_enqueueEvent == NULL) {
        // GetMethodID() returns a method ID, or NULL if the operation
        // fails. Returns NULL if and only if an invocation of this
        // function has thrown an exception.

        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to tosDebug() method in Java.
    ptII_jmethodID_tosDebug = (*env)->GetMethodID(env, cls, "tosDebug", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
    if (ptII_jmethodID_tosDebug == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to getCharParameterValue() method in Java.
    ptII_jmethodID_getCharParameterValue = (*env)->GetMethodID(env, cls, "getCharParameterValue", "(Ljava/lang/String;)C");
    if (ptII_jmethodID_getCharParameterValue == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    } 

    // Store handle to sendToPort() method in Java.
    ptII_jmethodID_sendToPort = (*env)->GetMethodID(env, cls, "sendToPort", "(Ljava/lang/String;Ljava/lang/String;)Z");
    if (ptII_jmethodID_sendToPort == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to startThreads() method in Java.
    ptII_jmethodID_startThreads = (*env)->GetMethodID(env, cls, "startThreads", "()V");
    if (ptII_jmethodID_startThreads == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to joinThreads() method in Java.
    ptII_jmethodID_joinThreads = (*env)->GetMethodID(env, cls, "joinThreads", "()Z");
    if (ptII_jmethodID_joinThreads == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    /////////////////////// Begin socket methods //////////////////////////
    
    // Store handle to serverSocketCreate() method in Java.
    ptII_jmethodID_serverSocketCreate = (*env)->GetMethodID(env, cls, "serverSocketCreate", "(S)Ljava/net/ServerSocket;");
    if (ptII_jmethodID_serverSocketCreate == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to serverSocketClose() method in Java.
    ptII_jmethodID_serverSocketClose = (*env)->GetMethodID(env, cls, "serverSocketClose", "(Ljava/net/ServerSocket;)V");
    if (ptII_jmethodID_serverSocketClose == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }
    
    // Store handle to selectorCreate() method in Java.
    ptII_jmethodID_selectorCreate = (*env)->GetMethodID(env, cls, "selectorCreate", "(Ljava/net/ServerSocket;ZZZZ)Ljava/nio/channels/Selector;");
    if (ptII_jmethodID_selectorCreate == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to selectorRegister() method in Java.
    ptII_jmethodID_selectorRegister = (*env)->GetMethodID(env, cls, "selectorRegister", "(Ljava/nio/channels/Selector;Ljava/nio/channels/SelectableChannel;ZZZZ)V");
    if (ptII_jmethodID_selectorRegister == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }  
    
    // Store handle to selectorClose() method in Java.
    ptII_jmethodID_selectorClose = (*env)->GetMethodID(env, cls, "selectorClose", "(Ljava/nio/channels/Selector;)V");
    if (ptII_jmethodID_selectorClose == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }    

    // Store handle to selectSocket() method in Java.
    ptII_jmethodID_selectSocket = (*env)->GetMethodID(env, cls, "selectSocket", "(Ljava/nio/channels/Selector;[ZZZZZ)Ljava/nio/channels/SelectableChannel;");
    if (ptII_jmethodID_selectSocket == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to acceptConnection() method in Java.
    ptII_jmethodID_acceptConnection = (*env)->GetMethodID(env, cls, "acceptConnection", "(Ljava/nio/channels/SelectableChannel;)Ljava/nio/channels/SocketChannel;");
    if (ptII_jmethodID_acceptConnection == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to socketChannelClose() method in Java.
    ptII_jmethodID_socketChannelClose = (*env)->GetMethodID(env, cls, "socketChannelClose", "(Ljava/nio/channels/SelectableChannel;)V");
    if (ptII_jmethodID_socketChannelClose == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }
    
    // Store handle to socketChannelWrite() method in Java.
    ptII_jmethodID_socketChannelWrite = (*env)->GetMethodID(env, cls, "socketChannelWrite", "(Ljava/nio/channels/SocketChannel;[B)I");
    if (ptII_jmethodID_socketChannelWrite == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to socketChannelRead() method in Java.
    ptII_jmethodID_socketChannelRead = (*env)->GetMethodID(env, cls, "socketChannelRead", "(Ljava/nio/channels/SocketChannel;[B)I");
    if (ptII_jmethodID_socketChannelRead == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    /////////////////////// End socket methods ////////////////////////////
    
    // --------------------------------------------------------------------
    // Reference to the Object class in Java.
    jclass objectClass;

    // Get reference to the class object whose instance is to be
    // created.
    if ((objectClass = (*env)->FindClass(env, "java/lang/Object")) == NULL) {
        // FindClass() returns a local reference to the named class or
        // interface, or NULL if the class or interface cannot be
        // loaded. Returns NULL if and only if an invocation of this
        // function has thrown an exception.

        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to Object.wait() method in Java.
    ptII_jmethodID_Object_wait =
        (*env)->GetMethodID(env, objectClass, "wait", "()V");
    if (ptII_jmethodID_Object_wait == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to Object.notify() method in Java.
    ptII_jmethodID_Object_notify =
        (*env)->GetMethodID(env, objectClass, "notify", "()V");
    if (ptII_jmethodID_Object_notify == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // Store handle to Object.notifyAll() method in Java.
    ptII_jmethodID_Object_notifyAll =
        (*env)->GetMethodID(env, objectClass, "notifyAll", "()V");
    if (ptII_jmethodID_Object_notifyAll == NULL) {
        // Handle Throwable in calling Java code.
        return -1;
    }

    // --------------------------------------------------------------------

    // DeleteLocalRef() does not result in any exceptions, so don't
    // check for any.
    (*env)->DeleteLocalRef(env, cls);
    
    // Set up arguments to main().
    // GetArrayLength() does not result in any exceptions, so don't
    // check for any.
    jsize len = (*env)->GetArrayLength(env, argsToMain);
    int argc = len + 1;
    char *argv[argc];

    // First argument is name of program.
    argv[0] = "main";              

    // Extract each arg from the jobjectArray and convert from a
    // jstring to a char*.
    int i;
    for (i = 0; i < len; i++) {
        jobject arg = (*env)->GetObjectArrayElement(env, argsToMain, i);
        if ((*env)->ExceptionOccurred(env)) {
            // GetObjectArrayElement() returns a local reference to
            // the element.  Throws ArrayIndexOutOfBoundsException if
            // index does not specify a valid index in the array.
            
            // Handle Throwable in calling Java code.
            return -1;
        }
        const char *argstr = (*env)->GetStringUTFChars(env, (jstring) arg, 0);
        if (argstr == NULL) {
            // GetStringUTFChars() returns a pointer to a UTF-8
            // string, or NULL if the operation fails. Returns NULL if
            // and only if an invocation of this function has thrown
            // an exception.

            // Handle Throwable in calling Java code.
            return -1;
        }
        
        argv[i+1] = (char *)argstr;
        // FIXME: when to release string?
        //(*env)->ReleaseStringUTFChars(env, prompt, str);
    }
    
    // Call main() with extracted arguments.
    main(argc, argv);
    return 0;
}

/* Native method called from Java.
   Call fire() to process a single event and all TinyOS tasks in the
   TOSSIM queue.
   Arguments:
     currentTime: the current ptII time.
 */
JNIEXPORT void JNICALL PTII_NATIVE_METHOD(_processEvent, _PTII_NODE_NAME, (JNIEnv *env, jobject obj, jlong currentTime)) {
    ptII_fire(currentTime);
}

/* Native method called from Java.
   Call ptII_receive_packet() to process a packet received from the
   Java environment.
   Arguments:
     currentTime: the current ptII time
     packet: received packet.
*/
JNIEXPORT void JNICALL PTII_NATIVE_METHOD(_receivePacket, _PTII_NODE_NAME, (JNIEnv *env, jobject obj, jlong currentTime, jstring packet)) {
    const char *msg = (*env)->GetStringUTFChars(env, (jstring) packet, 0);
    
    // FIXME: when to release string?
    //(*env)->ReleaseStringUTFChars(env, prompt, str);

    ptII_receive_packet(currentTime, msg);
}

/* Native method called from Java.
   Wrapup by shutting down ports.
*/
JNIEXPORT void JNICALL PTII_NATIVE_METHOD(_wrapup, _PTII_NODE_NAME, (JNIEnv *env, jobject obj)) {
    shutdownSockets();
}

/* Native method called from Java.
   Start the commandReadThread.
*/
JNIEXPORT void JNICALL PTII_NATIVE_METHOD(_commandReadThread, _PTII_NODE_NAME, (JNIEnv *env, jobject obj)) {
    commandReadThreadFunc(NULL);
}

/* Native method called from Java.
   Start the eventAcceptThread.
*/
JNIEXPORT void JNICALL PTII_NATIVE_METHOD(_eventAcceptThread, _PTII_NODE_NAME, (JNIEnv *env, jobject obj)) {
    eventAcceptThreadFunc(NULL);
}

/* Called from queue_insert_event() in event_queue.c.  This calls
   enqueueEvent() in ptII which will call fireAt() on the director.
   Arguments:
     eventTime: Time at which event should occur.
 */
void ptII_queue_insert_event(long long eventTime) {
    JNIEnv *env = ptII_JNIEnv_env;
    jobject obj = ptII_global_obj;

    int len = 128;
    char timeVal[len];
    snprintf(timeVal, len, "%lld", eventTime);
    //printf("ptII_queue_insert_event: %s\n", timeVal);
    jstring str = NULL;
    if ((str = (*env)->NewStringUTF(env, timeVal)) == NULL) {
        // NewStringUTF() Returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for eventTime using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
        
    // Call enqueueEvent() in Java.
    (*env)->CallVoidMethod(env, obj, ptII_jmethodID_enqueueEvent, str);
    // Check for exception, in case it wasn't properly handled in Java.
    if ((*env)->ExceptionOccurred(env)) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to PtinyOSDirector.enqueueEvent() generated an unhandled exception.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
}

/* Called from dbg() and dbg_clear() in
   tinyos-1.x/contrib/ptII/ptinyos/tos/types/dbg.h.  This calls
   tosDebug() in ptII which captures the debug messages.  Might be
   called from pthreads in external_comm.c, so we must get the
   environment for the current thread to use with the JVM.
   Arguments:
     dbgmode: debug mode (see tinyos-1.x/contrib/ptII/ptinyos/tos/types/dbg.h)
     msg: debug message
     nodenum: node ID number
     useNodenum: flag to determine whether to display nodenum
       in printed error message.
*/
void ptII_dbg(long long dbgmode, char *msg, short nodenum, int useNodenum) {
    JNIEnv *env = NULL;
    jobject obj = ptII_global_obj;

    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return;
    }
    
    // Length of buffers to hold strings for numbers.
    int len = 128;
    
    // Convert dbgmode into jstring
    char dbgmodeStr[len];
    snprintf(dbgmodeStr, len, "%lld", dbgmode);
    jstring dbgmodeJstring = NULL;
    if ((dbgmodeJstring = (*env)->NewStringUTF(env, dbgmodeStr)) == NULL) {
        // NewStringUTF() Returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for dbgmode using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }

    // Convert msg into jstring
    jstring msgJstring = NULL;
    if ((msgJstring = (*env)->NewStringUTF(env, msg)) == NULL) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for msg using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
    
    
    if (useNodenum) {
        // Convert nodenum into jstring
        char nodenumStr[len];
        snprintf(nodenumStr, len, "%i", nodenum);
        jstring nodenumJstring = NULL;
        if ((nodenumJstring = (*env)->NewStringUTF(env, nodenumStr)) == NULL) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCould not create string for msg using NewStringUTF()", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        }

        // Call tosDebug() in Java.
        (*env)->CallVoidMethod(env, obj, ptII_jmethodID_tosDebug,
                dbgmodeJstring, msgJstring, nodenumJstring);
    } else {
        (*env)->CallVoidMethod(env, obj, ptII_jmethodID_tosDebug,
                dbgmodeJstring, msgJstring, NULL);
    }
    
    // Check for exception, in case it wasn't properly handled in Java.
    if ((*env)->ExceptionOccurred(env)) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to PtinyOSDirector.tosDebug() generated an unhandled exception.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
}

/* Send LED data to Java by calling sendToPort() on the LED ports.
   Arguments:
     moteID: mote ID number
     red: value of red LED
     green: value of green LED
     yellow: value of yellow LED
 */
void ptII_updateLeds(int moteID, short red, short green, short yellow) {
    JNIEnv *env = ptII_JNIEnv_env;
    jobject obj = ptII_global_obj;

    // ====================== Red LED =========================
    char *redPortname = "ledRed";
    jstring redPortnameJstring = NULL;
    if ((redPortnameJstring = (*env)->NewStringUTF(env, redPortname)) == NULL) {
        // NewStringUTF() returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for ledRed using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }

    char *redValue = (red) ? "true" : "false";
    jstring redJstring = NULL;
    if ((redJstring = (*env)->NewStringUTF(env, redValue)) == NULL) {
        // NewStringUTF() returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for ledRed value using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }    

    // sendToPort() returns true if the expression was successfully
    // sent, false if the port is not connected or not found.
    jboolean redRet = (*env)->CallBooleanMethod(env, obj, ptII_jmethodID_sendToPort, redPortnameJstring, redJstring);
    if (redRet == JNI_FALSE) {
        jthrowable redThrowable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (redThrowable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to PtinyOSDirector.sendToPort() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        } else {
            fprintf(stderr, "Error in %s[%d]: Call to sendToPort() for ledRed returned false.\n", __FILE__, __LINE__);
        }
    }

    // ====================== Green LED =========================
    char *greenPortname = "ledGreen";
    jstring greenPortnameJstring = NULL;
    if ((greenPortnameJstring = (*env)->NewStringUTF(env, greenPortname)) == NULL) {
        // NewStringUTF() returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for ledGreen using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
        
    char *greenValue = (green) ? "true" : "false";
    jstring greenJstring = NULL;
    if ((greenJstring = (*env)->NewStringUTF(env, greenValue)) == NULL) {
        // NewStringUTF() returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for ledGreen value using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }

    // sendToPort() returns true if the expression was successfully
    // sent, false if the port is not connected or not found.
    jboolean greenRet = (*env)->CallBooleanMethod(env, obj, ptII_jmethodID_sendToPort, greenPortnameJstring, greenJstring);
    if (greenRet == JNI_FALSE) {
        jthrowable greenThrowable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (greenThrowable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to PtinyOSDirector.sendToPort() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        } else {
            fprintf(stderr, "Error in %s[%d]: Call to sendToPort() for ledGreen returned false.\n", __FILE__, __LINE__);
        }
    }
    
    // ====================== Yellow LED =========================
    char *yellowPortname = "ledYellow";
    jstring yellowPortnameJstring = NULL;
    if ((yellowPortnameJstring = (*env)->NewStringUTF(env, yellowPortname)) == NULL) {
        // NewStringUTF() returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for ledYellow using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
    
    char *yellowValue = (yellow) ? "true" : "false";
    jstring yellowJstring = NULL;
    if ((yellowJstring = (*env)->NewStringUTF(env, yellowValue)) == NULL) {
        // NewStringUTF() returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for ledYellow value using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
    
    // sendToPort() returns true if the expression was successfully
    // sent, false if the port is not connected or not found.
    jboolean yellowRet = (*env)->CallBooleanMethod(env, obj, ptII_jmethodID_sendToPort, yellowPortnameJstring, yellowJstring);
    if (yellowRet == JNI_FALSE) {
        jthrowable yellowThrowable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (yellowThrowable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to PtinyOSDirector.sendToPort() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        } else {
            fprintf(stderr, "Error in %s[%d]: Call to sendToPort() for ledYellow returned false.\n", __FILE__, __LINE__);
        }
    }
}

/* Called from generic_adc_read() in adc_model.c
   Gets a sensor data value from port with name "portname" in ptII by
   calling getCharParameterValue().
   Argument:
     portname: port from which to get data.
   Returns: unsigned short representing sensor data value
 */
unsigned short ptII_get_adc_value(char *portname) {
    JNIEnv *env = ptII_JNIEnv_env;
    jobject obj = ptII_global_obj;
    
    jstring portnameJstring = NULL;
    if ((portnameJstring =(*env)->NewStringUTF(env, portname)) == NULL) {
        // NewStringUTF() returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for adc portname value using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }

    // getCharParameterValue() returns the parameter value, or 0 if
    // the port is not connected or not found.
    jchar ret = (*env)->CallCharMethod(env, obj, ptII_jmethodID_getCharParameterValue, portnameJstring);
    if (ret == 0) {
        jthrowable throwable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to PtinyOSDirector.getCharParameterValue() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        }
    }
    return (unsigned short) ret;
}

/* Called from event_start_transmit_handle() in
   tinyos-1.x/contrib/ptII/ptinyos/beta/TOSSIM-packet/packet_sim.c.
   Sends a packet to the Java environment by calling
   PtinyOSDirector.sendToPort().
   Arguments:
     msg: the packet to send to Java.
*/
void ptII_send_packet(TOS_MsgPtr msg) {
    JNIEnv *env = ptII_JNIEnv_env;
    jobject obj = ptII_global_obj;
    
    int i;

    char packetStr[(sizeof(TOS_Msg) * 2) + 1];
    for (i = 0; i < sizeof(packetStr); i++) {
        packetStr[i] = '\0';
    }
    for (i = 0; i < sizeof(TOS_Msg); i++) {
        sprintf(&packetStr[2*i], "%02hhx", ((unsigned char *) msg)[i]);
    }

    jstring packetJstring = NULL;
    if ((packetJstring = (*env)->NewStringUTF(env, packetStr)) == NULL) {
        // NewStringUTF() returns a local reference to a string
        // object, or NULL if the string cannot be
        // constructed. Returns NULL if and only if an invocation of
        // this function has thrown an exception.
        
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for packet value using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
    
    jstring packetOutPortnameJString = NULL;
    if ((packetOutPortnameJString = (*env)->NewStringUTF(env, "packetOut")) == NULL) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCould not create string for packet portname value using NewStringUTF()", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }

    // sendToPort() returns true if the expression was successfully
    // sent, false if the port is not connected or not found.
    jboolean packetRet = (*env)->CallBooleanMethod(env, obj, ptII_jmethodID_sendToPort, packetOutPortnameJString, packetJstring);
    if (packetRet == JNI_FALSE) {
        jthrowable throwable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to PtinyOSDirector.sendToPort() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        } else {
            fprintf(stderr, "Error in %s[%d]: Call to sendToPort() for packetOut returned false.\n", __FILE__, __LINE__);       
        }
    }
}

/* Called from PTII_NATIVE_METHOD(_receivePacket, ...)
   Process a packet received from Java.  This function copies the
   received C const char array into a TOS_Msg data structure. It then
   calls TOSSIM ptII_insert_packet_event(), which creates a TOSSIM
   packet event.
   Arguments:
     ptolemyTime: the current ptII time
     packet: the packet received from Java.
 */
void ptII_receive_packet(long long ptolemyTime, const char *packet) {
    TOS_Msg msg;
    TOS_MsgPtr msgptr = &msg;
    unsigned char *charptr = (unsigned char *) msgptr;

    int i;

    // Read byte array for packet into TOS_Msg
    for (i = 0; i < sizeof(TOS_Msg); i++) {
        short s;
        sscanf(&packet[i*2], "%2hx", &s);
        charptr[i] = (unsigned char) s;
    }

    // This will copy msgptr into a new malloc'd TOS_MsgPtr.
    ptII_insert_packet_event(ptolemyTime, msgptr);
}

/* This is called from initializeSockets() in external_comm.c.  This
   relies on the fact that the thread that calls this from
   external_comm.c is the same as the thread that calls the other
   functions above.
*/
void ptII_startThreads() {
    JNIEnv *env = ptII_JNIEnv_env;
    jobject obj = ptII_global_obj;

    (*env)->CallVoidMethod(env, obj, ptII_jmethodID_startThreads);
    jthrowable throwable = NULL;
    // Check for exception, in case it wasn't properly handled in Java.
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
            
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to loader.startThreads() generated exception.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }  
}

/* This is called from shutdownSockets() in external_comm.c.  This
   relies on the fact that the thread that calls this from
   external_comm.c is the same as the thread that calls the other
   functions above.
   Returns: 0 on failure, otherwise success.
*/
int ptII_joinThreads() {
    JNIEnv *env = ptII_JNIEnv_env;
    jobject obj = ptII_global_obj;
    
    // joinThreads() returns true if successful, otherwise false.
    jboolean retVal = (*env)->CallBooleanMethod(env, obj, ptII_jmethodID_joinThreads);
    if (retVal == JNI_FALSE) {
        // Check for exception, in case it wasn't properly handled in Java.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to loader.joinThreads() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        }
    } 
    return (retVal == JNI_TRUE) ? 1 : 0;
}

/////////////////////// Begin socket methods //////////////////////////
//
//  All of these socket methods are called from TOSSIM to call methods
//  in PtinyOSDirector that manipulate Java sockets.
//
///////////////////////////////////////////////////////////////////////

/* Create a non-blocking server socket and check for connections on the 
 *   port specified by "port".
 * Arguments:
 *   port: The port number on which to create a server socket.
 * Returns: The ServerSocket created (type ServerSocket).
 */
void* ptII_serverSocketCreate(short port) {
    JNIEnv *env = NULL;
    jobject obj = ptII_global_obj;
    
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL;
    }

    // Call serverSocketCreate() in Java.
    // serverSocketCreate() returns the ServerSocket created, or null
    // if error.
    jobject serverSocket = (*env)->CallObjectMethod(env, obj, ptII_jmethodID_serverSocketCreate, port);
    if (serverSocket == NULL) {
        jthrowable throwable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to loader.serverSocketCreate() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        }
    }

    // Create a global reference so that we can save the reference to
    // the lock object over multiple calls.
    if ((serverSocket = (*env)->NewGlobalRef(env, serverSocket)) == NULL) {
        // NewGlobalRef() returns a global reference. The result is NULL
        // if the system runs out of memory, if the given argument is
        // NULL, or if the given reference is a weak global reference
        // referring to an object that has already been garbage
        // collected.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to NewGlobalRef() returned NULL.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL; 
    }    
    
    return serverSocket;
}

/* Close the ServerSocket.
 * Arguments:
 *   serverSocket: The ServerSocket to be closed (type ServerSocket).
 */
void ptII_serverSocketClose(void *serverSocket) {
    jobject obj = ptII_global_obj;
        
    JNIEnv *env;
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return;
    }

    // Call serverSocketClose() in Java.
    (*env)->CallVoidMethod(env, obj, ptII_jmethodID_serverSocketClose, (jobject)serverSocket);
    jthrowable throwable = NULL;
    // Check for exception, in case it wasn't properly handled in Java.
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
            
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to loader.serverSocketClose() generated exception.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }    
}

/* Create a selector and register the ServerSocketChannel of the 
 *  ServerSocket with the selector.
 * Note that in nesC, bool is unsigned char.
 * Arguments:
 *   serverSocket: The ServerSocket whose channel should be
 *     registered with the Selector created (type ServerSocket).
 *   opAccept: True if this SelectionKey option that should
 *     be enabled when registering the ServerSocketChannel to the
 *    Selector (boolean flag).
 *   opConnect: True if this SelectionKey option that should
 *     be enabled when registering the ServerSocketChannel to the
 *     Selector (boolean flag).
 *   opRead: True if this SelectionKey option that should be
 *     enabled when registering the ServerSocketChannel to the
 *     Selector (boolean flag).
 *   opWrite: True if this SelectionKey option that should be
 *     enabled when registering the ServerSocketChannel to the
 *     Selector (boolean flag).
 *  Returns: The Selector created (type Selector), or null if error.
 */
void* ptII_selectorCreate(void *serverSocket, unsigned char opAccept,
        unsigned char opConnect, unsigned char opRead, unsigned char opWrite) {
    jobject obj = ptII_global_obj;
        
    JNIEnv *env;
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL;
    }

    // Call selectorCreate() in Java.
    // selectorCreate() returns the Selector created, or null if error.
    jobject selector = (*env)->CallObjectMethod(env, obj, ptII_jmethodID_selectorCreate, (jobject)serverSocket, (jboolean)opAccept, (jboolean)opConnect, (jboolean)opRead, (jboolean)opWrite);
    if (selector == NULL) {
        jthrowable throwable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to loader.selectorCreate() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
            return NULL;
        }      
    }
    
    // Create a global reference so that we can save the reference to
    // the lock object over multiple calls.
    if ((selector = (*env)->NewGlobalRef(env, selector)) == NULL) {
        // NewGlobalRef() returns a global reference. The result is NULL
        // if the system runs out of memory, if the given argument is
        // NULL, or if the given reference is a weak global reference
        // referring to an object that has already been garbage
        // collected.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to NewGlobalRef() returned NULL.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL; 
    }    
    
    return selector;
}

/* Register the channel with the selector
 * Note that in nesC, bool is unsigned char.
 * Arguments:
 *   selector: The selector to which the channel should be registered
 *     (type Selector).
 *   socketChannel: The SocketChannel that should be registered
 *     (type SocketChannel).
 *   opAccept: True if this SelectionKey option that should
 *     be enabled when registering the SocketChannel to the Selector
 *     (boolean flag).
 *   opConnect: True if this SelectionKey option that should
 *     be enabled when registering the SocketChannel to the Selector
 *     (boolean flag).   
 *   opRead: True if this SelectionKey option that should be
 *     enabled when registering the SocketChannel to the Selector
 *     (boolean flag).   
 *   opWrite: True if this SelectionKey option that should be
 *     enabled when registering the SocketChannel to the Selector
 *     (boolean flag).   
*/
void ptII_selectorRegister(void *selector, void *socketChannel, unsigned char opAccept, unsigned char opConnect, unsigned char opRead, unsigned char opWrite) {
    jobject obj = ptII_global_obj;
    JNIEnv *env;

    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return;
    }

    // Call selectorRegister() in Java
    (*env)->CallVoidMethod(env, obj, ptII_jmethodID_selectorRegister, (jobject)selector, (jobject)socketChannel, (jboolean)opAccept, (jboolean)opConnect, (jboolean)opRead, (jboolean)opWrite);
    jthrowable throwable = NULL;
    // Check for exception, in case it wasn't properly handled in Java.
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
            
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to loader.selectorRegister() generated exception.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }    
}

/* Close the Selector.
 *
 * Called from external_comm.c: eventAcceptThreadFunc() and
 * commandReadThreadFunc().
 *
 * Arguments:
 *   selector: The selector that should be closed (type Selector).
 */
void ptII_selectorClose(void *selector) {
    jobject obj = ptII_global_obj;
        
    JNIEnv *env;
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return;
    }

    // Call selectorClose() in Java
    (*env)->CallVoidMethod(env, obj, ptII_jmethodID_selectorClose, (jobject)selector);
    jthrowable throwable = NULL;
    // Check for exception, in case it wasn't properly handled in Java.
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
            
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to loader.selectorClose() generated exception.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }
}

/* Call select().
 *
 * selectorIsClosing[0] gets set to true (value = 1) if the selector is
 * about to close.
 *
 * Called from external_comm.c: eventAcceptThreadFunc() and
 * commandReadThreadFunc().
 *
 * Also see:
 *   $PTII/ptolemy/domains/ptinyos/kernel/PtinyOSDirector.java: selectorClose()
 *
 * Note that in nesC, bool is unsigned char.
 *
 * Arguments:
 *   selector: The channel selector.
 *   notNullIfClosing: TRUE if returning NULL, otherwise left
 *     as is.  We use notNullIfClosing because of threading issues
 *     discussed in {@link #selectorClose(Selector selector)}
 *     (type boolean[]).
 *   opAccept: True if this SelectionKey option that should
 *     be enabled when returning a non-null SelectableChannel (type boolean).
 *   opConnect: True if this SelectionKey option that should
 *     be enabled when returning a non-null SelectableChannel (type boolean).
 *   opRead: True if this SelectionKey option that should be
 *     enabled when returning a non-null SelectableChannel (type boolean).
 *   opWrite: True if this SelectionKey option that should be
 *     enabled when returning a non-null SelectableChannel (type boolean).
 * Returns: The selected channel, or null if none (type SelectableChannel).
 *
 */
void* ptII_selectSocket(void *selector, char *selectorIsClosing, unsigned char opAccept, unsigned char opConnect, unsigned char opRead, unsigned char opWrite) {
    jobject obj = ptII_global_obj;
        
    JNIEnv *env;
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) { 
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL;
    }

    jbooleanArray booleanArray;
    if ((booleanArray = (*env)->NewBooleanArray(env, 1)) == NULL) {
        // NewBooleanArray() returns a local reference to a primitive
        // array, or NULL if the array cannot be constructed. Returns
        // NULL if and only if an invocation of this function has
        // thrown an exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
            return NULL;
        }
    }
        
    // Call selectSocket() in Java.
    // selectSocket() returns the selected channel, or null if none.
    jobject serverSocketChannel = (*env)->CallObjectMethod(env, obj, ptII_jmethodID_selectSocket, (jobject)selector, booleanArray, (jboolean)opAccept, (jboolean)opConnect, (jboolean)opRead, (jboolean)opWrite);
    if (serverSocketChannel == NULL) {
        jthrowable throwable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to loader.selectSocket() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
            return NULL;
        }
    }

    jboolean *dataRead = (*env)->GetBooleanArrayElements(env, booleanArray, NULL);
    if (dataRead == NULL) {
        // GetBooleanArrayElements() returns a pointer to the array
        // elements, or NULL if an exception occurs. Returns NULL if
        // and only if an invocation of this function has thrown an
        // exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
            return NULL;
        }
    }    

    *selectorIsClosing = dataRead[0];

    // Create a global reference so that we can save the reference to
    // the serverSocketChannel object over multiple calls.
    if ((serverSocketChannel = (*env)->NewGlobalRef(env, serverSocketChannel)) == NULL) {
        // NewGlobalRef() returns a global reference. The result is NULL
        // if the system runs out of memory, if the given argument is
        // NULL, or if the given reference is a weak global reference
        // referring to an object that has already been garbage
        // collected.

        // Selector is about to close (serverSocketChannel was NULL).
        if (*selectorIsClosing) {
            return NULL;
        }

        // NewGlobalRef() does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to NewGlobalRef() returned NULL.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL; 
    }    
    
    return serverSocketChannel;
}

/* Accept a connection on a ServerSocketChannel.  If serverSocketChannel 
 * is blocking, this method blocks.
 * Arguments:
 *   serverSocketChannel: The ServerSocketChannel on which connections
 *     are accepted (type ServerSocketChannel).
 * Returns: The SocketChannel for the connection that was accepted
 * (type SocketChannel).
 */
void* ptII_acceptConnection(void *serverSocketChannel) {
    jobject obj = ptII_global_obj;
        
    JNIEnv *env;
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) { 
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL;
    }

    // Call acceptConnection() in Java.
    // acceptConnection() returns the SocketChannel for the connection
    // that was accepted, null if error.
    jobject socketChannel = (*env)->CallObjectMethod(env, obj, ptII_jmethodID_acceptConnection, (jobject)serverSocketChannel);
    if (socketChannel == NULL) {
        jthrowable throwable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to loader.acceptConnection() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
            return NULL;
        }
    }
    
    // Create a global reference so that we can save the reference to
    // the lock object over multiple calls.
    if ((socketChannel = (*env)->NewGlobalRef(env, socketChannel)) == NULL) {
        // NewGlobalRef() returns a global reference. The result is NULL
        // if the system runs out of memory, if the given argument is
        // NULL, or if the given reference is a weak global reference
        // referring to an object that has already been garbage
        // collected.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to NewGlobalRef() returned NULL.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL; 
    }    
    
    return socketChannel;
}

/* Close the SocketChannel.
 * Arguments:
 *   socketChannel: The SocketChannel to close (type SocketChannel).
 */
void ptII_socketChannelClose(void *socketChannel) {
    jobject obj = ptII_global_obj;
        
    JNIEnv *env;
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return;
    }

    // Call socketChannelClose() in Java
    (*env)->CallVoidMethod(env, obj, ptII_jmethodID_socketChannelClose, (jobject)socketChannel);
    jthrowable throwable = NULL;
    // Check for exception, in case it wasn't properly handled in Java.
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Print exception and stack trace to system error-reporting
        // channel (e.g., stderr).
        (*env)->ExceptionDescribe(env);
        // Clear exception that is currently being thrown.
        (*env)->ExceptionClear(env);
            
        // Create and thrown our own exception.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to loader.socketChannelClose() generated exception.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
    }     
}

/* Write the bytes in "data" to a SocketChannel.
 * Arguments:
 *   socketChannel: The SocketChannel on which to write (type SocketChannel).
 *   data: The data to write.
 *   datalen: Length of "data".
 * Returns: Number of bytes written.  -1 if error.
 */
int ptII_socketChannelWrite(void *socketChannel, void *data, int datalen) {
    jobject obj = ptII_global_obj;
        
    JNIEnv *env;
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return -1;
    }

    jbyteArray byteArray;
    if ((byteArray = (*env)->NewByteArray(env, datalen)) == NULL) {
        // NewByteArray() returns a local reference to a primitive
        // array, or NULL if the array cannot be constructed. Returns
        // NULL if and only if an invocation of this function has
        // thrown an exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
            return -1;
        }
    }
    
    // SetByteArrayRegion() returns void, but it could result in an
    // exception, so check for it.
    (*env)->SetByteArrayRegion(env, byteArray, 0, datalen, (jbyte *)data);
    jthrowable throwable = NULL;
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Throw the exception to ptII.
        (*env)->Throw(env, throwable);
        return -1;
    }
    
    // Call socketChannelWrite() in Java.
    // socketChannelWrite() returns number of bytes written.  -1 if error.
    jint retVal = (*env)->CallIntMethod(env, obj, ptII_jmethodID_socketChannelWrite, (jobject)socketChannel, byteArray);
    if ((int) retVal < 0) {
        // Check for exception, in case it wasn't properly handled in Java.
        throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to loader.socketChannelWrite() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
            return -1;
        }
    }   

    return (int) retVal;
}

/* Read from a SocketChannel into buffer pointed to by "data" with
 * length "datalen".
 * Arguments:
 *   socketChannel: SocketChannel from which to read.
 *   data: Pointer to buffer.
 *   datalen: Length of buffer.
 * Returns: Number of bytes read.  Returns 0 if end of stream
 *   reached, -1 if error.
 */
int ptII_socketChannelRead(void *socketChannel, void *data, int datalen) {
    jobject obj = ptII_global_obj;
        
    JNIEnv *env;
    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return -1;
    }

    jbyteArray byteArray;
    if ((byteArray = (*env)->NewByteArray(env, datalen)) == NULL) {
        // NewByteArray() returns a local reference to a primitive
        // array, or NULL if the array cannot be constructed. Returns
        // NULL if and only if an invocation of this function has
        // thrown an exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
            return -1;
        }
    }
    
    // Call socketChannelRead() in Java.
    // socketChannelRead() returns number of bytes read.  Returns 0 if
    // end of stream reached, -1 if error.
    jint retVal = (*env)->CallIntMethod(env, obj, ptII_jmethodID_socketChannelRead, (jobject)socketChannel, byteArray);
    if ((int) retVal < 0) {
        jthrowable throwable = NULL;
        // Check for exception, in case it wasn't properly handled in Java.
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Print exception and stack trace to system error-reporting
            // channel (e.g., stderr).
            (*env)->ExceptionDescribe(env);
            // Clear exception that is currently being thrown.
            (*env)->ExceptionClear(env);
            
            // Create and thrown our own exception.
            snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                    "\nError in %s[%d]: \nCall to loader.socketChannelWrite() generated exception.", 
                    __FILE__, __LINE__);
            JNU_ThrowByName(env,
                    "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
            return -1;
        }
    }
    
    jbyte *dataRead = (*env)->GetByteArrayElements(env, byteArray, NULL);
    if (dataRead == NULL) {
        // GetByteArrayElements() returns a pointer to the array
        // elements, or NULL if an exception occurs. Returns NULL if
        // and only if an invocation of this function has thrown an
        // exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
            return -1;
        }
    }
    
    // Copy data into destination pointer.
    int i;
    int len = (int) retVal;
    char *destBuf = data;
    for (i = 0; i < len; i++) {
        destBuf[i] = dataRead[i];
    }

    // ReleaseByteArrayElements() does not result in any exceptions,
    // so don't check for any.
    (*env)->ReleaseByteArrayElements(env, byteArray, dataRead, JNI_ABORT);
    
    return (int) retVal;
}

/////////////////////// End socket methods ////////////////////////////


/* Create a monitor object (jobject) and return it.
 * Returns: A blank monitor object (JNI type jobject, Java type Object).
 */
void *ptII_createMonitorObject() {
    // Variables for creating lock object.
    JNIEnv *env;
    jclass objectClass;
    jmethodID constructor;
    jobject lockObject = NULL;

    // Attach the current thread to the JVM if it has not already been
    // attached and get the environment.
    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **) &env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL;
    }

    // Get reference to the class object whose instance is to be
    // created.
    if ((objectClass = (*env)->FindClass(env, "java/lang/Object")) == NULL) {
        // FindClass() returns a local reference to the named class or
        // interface, or NULL if the class or interface cannot be
        // loaded. Returns NULL if and only if an invocation of this
        // function has thrown an exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
            return NULL;
        }       
    }

    // Get the method ID of the constructor to be executed in the
    // newly created instance.
    if ((constructor = (*env)->GetMethodID(env, objectClass, "<init>", "()V")) == NULL) {
        // GetMethodID() returns a method ID, or NULL if the operation
        // fails. Returns NULL if and only if an invocation of this
        // function has thrown an exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
            return NULL;
        }

    }

    // Create the lock object.
    if ((lockObject = (*env)->NewObject(env, objectClass, constructor)) == NULL) {
        //NewObject() returns a local reference to an object, or NULL
        //if the object cannot be constructed. Returns NULL if and
        //only if an invocation of this function has thrown an
        //exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
            return NULL;
        }
    }

    // Create a global reference so that we can save the reference to
    // the lock object over multiple calls.
    if ((lockObject = (*env)->NewGlobalRef(env, lockObject)) == NULL) {
        // NewGlobalRef() returns a global reference. The result is NULL
        // if the system runs out of memory, if the given argument is
        // NULL, or if the given reference is a weak global reference
        // referring to an object that has already been garbage
        // collected.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to NewGlobalRef() returned NULL.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return NULL; 
    }

    return lockObject;
}

/* Enter the monitor.
 * Arguments:
 *   monitorObject: The monitor object (JNI type jobject, Java type Object).
 * Returns: 0 if success, < 0 if error.
 */
int ptII_MonitorEnter(void *monitorObject) {
    // Get the JNIEnv pointer.
    JNIEnv *env;
    jobject lock;

    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **)&env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return -1;
    }

    lock = (jobject) monitorObject;

    if ((*env)->MonitorEnter(env, lock) < 0) {
        // MonitorEnter() returns zero on success; otherwise, returns
        // a negative value. Returns a negative number if and only if
        // an invocation of this function has thrown an exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
        }
        return -1;
    }

    return 0;
}

/* Exit the monitor.
 * Arguments:
 *   monitorObject: The monitor object (JNI type jobject, Java type Object).
 * Returns: 0 if success, < 0 if error.
 */
int ptII_MonitorExit(void *monitorObject) {
    // Get the JNIEnv pointer.
    JNIEnv *env;
    jobject lock;

    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **)&env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return -1;
    }

    lock = (jobject) monitorObject;
    
    if ((*env)->MonitorExit(env, lock) < 0) {
        // MonitorExit() returns zero on success; otherwise, returns a
        // negative value. Returns a negative number if and only if an
        // invocation of this function has thrown an exception.
        jthrowable throwable = NULL;
        if (throwable = (*env)->ExceptionOccurred(env)) {
            // Throw the exception to ptII.
            (*env)->Throw(env, throwable);
        }
        return -1;
    };

    return 0;
}

/* Call wait() on the monitorObject.
 * Arguments:
 *   monitorObject: The monitor object (JNI type jobject, Java type Object).
 */
void ptII_MonitorWait(void *monitorObject) {
    // Get the JNIEnv pointer.
    JNIEnv *env;
    jobject lock;

    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **)&env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return;
    }

    lock = (jobject) monitorObject;

    (*env)->CallVoidMethod(env, lock, ptII_jmethodID_Object_wait);
    jthrowable throwable = NULL;
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Throw the exception to ptII.
        (*env)->Throw(env, throwable);
    }
}

/* Call notify() on the monitorObject.
 * Arguments:
 *   monitorObject: The monitor object (JNI type jobject, Java type Object).
 */
void ptII_MonitorNotify(void *monitorObject) {
    // Get the JNIEnv pointer.
    JNIEnv *env;
    jobject lock;

    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **)&env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return;
    }

    lock = (jobject) monitorObject;

    (*env)->CallVoidMethod(env, lock, ptII_jmethodID_Object_notify);
    jthrowable throwable = NULL;
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Throw the exception to ptII.
        (*env)->Throw(env, throwable);
    }
}

/* Call notifyAll() on the monitorObject.
 * Arguments:
 *   monitorObject: The monitor object (JNI type jobject, Java type Object).
 */
void ptII_MonitorNotifyAll(void *monitorObject) {
    // Get the JNIEnv pointer.
    JNIEnv *env;
    jobject lock;

    if ((*ptII_vm)->AttachCurrentThread(ptII_vm, (void **)&env, NULL) < 0) {
        // AttachCurrentThread() returns zero on success; otherwise,
        // returns a negative number.
        // Does not throw an exception, so throw our own.
        snprintf(ERROR_MESSAGE, sizeof(ERROR_MESSAGE),
                "\nError in %s[%d]: \nCall to AttachCurrentThread() returned a negative number.", 
                __FILE__, __LINE__);
        JNU_ThrowByName(env,
                "ptolemy/kernel/util/InternalErrorException", ERROR_MESSAGE);
        return;
    }

    lock = (jobject) monitorObject;

    (*env)->CallVoidMethod(env, lock, ptII_jmethodID_Object_notifyAll);
    jthrowable throwable = NULL;
    if (throwable = (*env)->ExceptionOccurred(env)) {
        // Throw the exception to ptII.
        (*env)->Throw(env, throwable);
    }    
}
