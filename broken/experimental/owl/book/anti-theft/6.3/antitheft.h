#ifndef ANTITHEFT_H
#define ANTITHEFT_H

enum { AM_THEFT = 42, AM_SETTINGS = 43 };

typedef nx_struct theft {
  nx_uint16_t who;
} theft_t;

typedef nx_struct settings {
  nx_uint16_t accelVariance;
  nx_uint16_t accelInterval;
} settings_t;

#endif
