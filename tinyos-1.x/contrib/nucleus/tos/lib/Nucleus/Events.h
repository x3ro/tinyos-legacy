//$Id: Events.h,v 1.3 2005/06/14 18:10:10 gtolle Exp $

#ifndef __EVENTS_H__
#define __EVENTS_H__

typedef uint16_t EventID;

struct @nucleusEvent {
  uint16_t key;
};

struct @nucleusEventString {
  char* string;
};

enum {
  LOG_DEBUG = 1,
  LOG_INFO = 2,
  LOG_WARN = 3,
  LOG_ERROR = 4,
  LOG_FATAL = 5,
};

#endif
