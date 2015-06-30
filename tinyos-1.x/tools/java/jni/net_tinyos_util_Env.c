// $Id: net_tinyos_util_Env.c,v 1.4 2003/10/07 21:45:49 idgay Exp $

#include "net_tinyos_util_Env.h"
#include <stdlib.h>


JNIEXPORT jstring JNICALL Java_net_tinyos_util_Env_igetenv
  (JNIEnv *env, jclass c, jstring jname)
{
  const char *name, *value;

  if (jname == NULL)
    return NULL;

  name = (*env)->GetStringUTFChars(env, jname, (jboolean *)NULL);

  value = getenv(name) ;

  (*env)->ReleaseStringUTFChars(env, jname, name);

  return value ? (*env)->NewStringUTF(env, value) : NULL;
}
