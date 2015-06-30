#ifndef TOSSIM_H_INCLUDED
#define TOSSIM_H_INCLUDED

#ifndef TOSNODES
#define TOSNODES 1000
#endif

#include "event_queue.h"
#include "events.h"
#include "rfm_model.h"

typedef struct TOS_node_state{
  long long time; // Time at which mote booted
  int pot_setting;
} TOS_node_state_t;

typedef struct TOS_state {
  long long tos_time;
  short num_nodes;
  short current_node;
  TOS_node_state_t node_state[TOSNODES];
  event_queue_t queue;
  rfm_model* rfm;
} TOS_state_t;

#define NODE_NUM (tos_state.current_node)
#define THIS_NODE (tos_state.node_state[tos_state.current_node])
#define TOS_queue_insert_event(event) \
        queue_insert_event(&(tos_state.queue), event);

extern TOS_state_t tos_state;

extern void sim_LED(char* color, int state);
extern void sim_ClockInit();
extern void sim_ADCinit();
extern void sim_ADCget(int channel);
extern int sim_ADCdata();

extern char sim_RFMreadBit();
extern void sim_RFMwriteBit(char* data);
extern void sim_RFMidleMode();
extern void sim_RFMrxMode();
extern void sim_RFMtxMode();

#endif
