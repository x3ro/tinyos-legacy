#ifndef BT_SIMPLEQUEUE_H
#define BT_SIMPLEQUEUE_H

#include <string.h>

struct simpleq {
     int used;
     int allocated;
     struct BTPacket** q;
};

static inline
void simpleq_init(struct simpleq* q) {
     q->used = 0;
     q->allocated = 20;
     q->q = (struct BTPacket**)malloc(sizeof(struct BTPacket*) * q->allocated);
     dbg(DBG_MEM, "new simpleq.\n");
}

static inline
void simpleq_enque(struct simpleq* q, struct BTPacket* p) {
     if (q->used == q->allocated) {
          q->q = realloc(q->q, 2 * sizeof(struct BTPacket*) * q->used);
          q->allocated *= 2;
          dbg(DBG_MEM, "bigger simpleq.\n");
     }
     q->q[q->used++] = p;
}

static inline
struct BTPacket* simpleq_deque(struct simpleq* q, int pktSize) {
     struct BTPacket* p;
     struct hdr_bt* bt;
     if (!q->used)
          return NULL;
     p = q->q[0];
     bt = &(p->bt);
     if(SlotSize[bt->type] <= pktSize) {
          q->used--;
          if (q->used) //dont do this if there are no elems anyway
               memmove(q->q[0], q->q[1], sizeof(struct BTPacket*) * q->used);
     }
     else {
          p = NULL;
     }
     return p;
}


#endif
