#ifndef __LOCALIZATION_H__
#define __LOCALIZATION_H__


typedef struct location_t{
  int32_t x;
  int32_t y;
} location_t;


enum {
  DEFAULT_LOCATION_CHANNEL = ATTRIBUTE_GPSLOCATION
};

#endif //__LOCALIZATION_H__
