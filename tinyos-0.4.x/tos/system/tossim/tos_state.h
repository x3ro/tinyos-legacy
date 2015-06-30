#ifndef TOS_STATE_H_INCLUDED
#define TOS_STATE_H_INCLUDED

#ifndef TOSNODES
#define TOSNODES 1
#endif


typedef struct TOS_node_state {
  int time;
  int level;
  int radio_active;
} TOS_node_state_t;

typedef struct TOS_state {
  int tos_time;
  int current_node;
  TOS_node_state node_state[TOSNODES];
} TOS_state_t;

extern void simLED(char* color, int state);
extern void simClockInit();
extern void simADCinit();
extern void simADCget(int channel);
extern int simADCdata();

extern char simRFMreadBit();
extern void simRFMwriteBit(data);
extern void simRFMidleMode();
extern void simRFMrxMode();
extern void simRFMtxMode();

#endif
