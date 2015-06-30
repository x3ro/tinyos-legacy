#ifndef _H_Wave_h
#define _H_Wave_h

enum { MAX_WAVES = 6 };

enum { RANGING_WAVE = 1 };

typedef struct {
  uint8_t level;
  uint16_t timer;
  uint16_t timerBase;
  uint16_t timerMask;
} wave_element_t;

#endif
