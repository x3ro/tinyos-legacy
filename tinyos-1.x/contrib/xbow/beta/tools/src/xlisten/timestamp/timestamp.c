/**
 * Standard TinyOS license here.
 */

/**
 * Parts of this code were developed as part of 
 * the NSF-ITR FireBug project.
 *
 * @author David M. Doolin
 *
 * @url http://firebug.sourceforge.net
 *
 */

/**
 * $Id: timestamp.c,v 1.2 2004/09/30 02:53:57 mturon Exp $
 */

#include <time.h>
#include <stdlib.h>
#include <memory.h>
#include <locale.h>

#include "timestamp.h"


#ifdef __cplusplus
extern "C" {
#endif

struct _timestamp {

  struct tm * time;
};



Timestamp *  
timestamp_new (void) {

  Timestamp * ts = (Timestamp*)malloc(sizeof(Timestamp));
  // Shred memory to indicate initialization status.
  memset((void*)ts,0xda,sizeof(Timestamp));
  return ts;
}


void         
timestamp_delete (Timestamp * ts) {
  
  // Shred memory going out to indicate invalid access.
  memset((void*)ts,0xdd,sizeof(Timestamp));
  free(ts);
}


/** @brief Get a timestamp in MySQL compatible format.
 * The innards could probably be slightly 
 * improved.  See header file to check/adjust
 * TIMESTRING_SIZE
 *
 * @author David M. Doolin
 */
void
timestamp_get_ymdhms (Timestamp * ts, char timestring[TIMESTRING_SIZE]) {

  struct tm * l_time = ts->time;
  time_t timetype;

  timetype = time(NULL);
  l_time = localtime(&timetype);

  strftime(timestring, TIMESTRING_SIZE, "%Y%m%d%H%M%S", l_time);
}


/**
 * Return string of timestamp in YYYY/MM/DD hh:mm:ss format. 
 * 
 * @version   2004/9/27     mturon     Initial revision 
 */
void
timestamp_get_string (Timestamp * ts, char timestring[TIMESTRING_SIZE]) {

  struct tm * l_time = ts->time;
  time_t timetype;

  timetype = time(NULL);
  l_time = localtime(&timetype);

  strftime(timestring, TIMESTRING_SIZE, "%Y/%m/%d %H:%M:%S", l_time);
}

#ifdef __cplusplus
}
#endif
