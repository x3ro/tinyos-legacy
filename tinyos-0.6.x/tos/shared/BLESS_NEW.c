/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Phil Levis
 *
 *
 */

/*
 *   FILE: BLESS_NEW.c
 * AUTHOR: pal
 *  DESCR: Probabilistic beaconless routing protocol - ALPHA
 *
 *  BLESS_NEW is a Beacon-LESS routing protocol for TinyOS, intended
 *  to deprecate BLESS. It handles the presence of asymmetric
 *  links. It is also entirely time-independent; its behavior on a
 *  frequently transmitting network should be the same as on an
 *  infrequently transmitting one (except its adjustments will be
 *  slower, etc.). It is therefore useful for bursty, long-term, or
 *  short-term networks. It uses probabilistic hop-count based metrics
 *  for packet forwarding.

 *  All data messages are sent as AM-level broadcasts; motes sniff
 *  data traffic intended for other motes. All motes maintain a
 *  weighted cache of parents. Cache weight is initially determined by
 *  hop count, and is later adjusted by the reliability of the link.
 *  Link reliability is measured by noting packet retransmissions
 *  (when mote A sends a packet to mote B and then hears it forward it
 *  to C). 
 *  
 *  Because cache weight is adjusted by retransmission (or lack
 *  thereof), a mote must transmit to all the possible parents in its
 *  cache. However, transmitting to the "best" parent is obviously
 *  preferable. These two conflicting needs are balanced through an
 *  exponential distribution for parent forwarding selection. Given a
 *  packet to forward, a mote will forward it to its "best" parent 50%
 *  of the time, its next best 25%, its third best 12.5%, etc. This
 *  way, a mote will obtain link quality information on all of its
 *  parents, the accuracy of that information will change at a rate
 *  proportional to how much that link is used, and most packets will
 *  be sent on the better links.
 *
 *  A mote's hop value is a weighted value calculated from its parent
 *  cache. Each entry is weighted by its probability of packet
 *  forwarding (50%, 25%, 12.5%, etc.). One is added to this total. This
 *  value is the hop count of the mote.
 *
 *  A simple probabilistic forwarding mechanism has problems, however;
 *  since cache weight can be different from hop distance from the
 *  root of the network, it's very possible that a packet will just
 *  bounce around the network without making forward progress towards
 *  the base. An assurance of monotonicity of progress is needed.
 *
 *  This assurance is provided through a TTL field in packets. The TTL
 *  begins at a value equal to twice its hop count value. Each time a
 *  packet is forwarded, the TTL is decremented by one. A packet
 *  cannot be forwarded to a mote whose hop count is greater than the
 *  TTL. If a packet with TTL $t$ is sent to a mote M with hop count
 *  $m$, the hop-count weighting algorithm assures that M has a parent
 *  with a hop count < $m$, and as $m$ < $t$, the packet is assured to
 *  make progress towards the base. This doubling of the TTL at
 *  initial transmit can be thought of as a pool of sub-optimal
 *  transmissions that can be made.
 *
 *  This routing component also has a fast-start mechanism. This
 *  component uses broadcast PING floods (PING.comp); the sequence
 *  number in the PING messages is the hop count of the mote sending
 *  the ping. This can be used to quickly establish a network by
 *  flooding, which will then slowly evolve as links show different
 *  levels of reliability.
 *
 *  The command BLESS_NEW_INIT must be called or mapped to MAIN_SUB_INIT
 *  for the BLESS component to work. The application bless_test shows
 *  a trivial example use of BLESS.
 *
 */

/* Always use the bless_new_msg structure when messing with messages. */

#include "tos.h"
#include "BLESS_NEW.h"
#include "bless_new_msg.h"
#include "dbg.h"

typedef struct bless_cache_t {
  char  weight;
  char  state;
  char  hops;
  char  heard;
  short moteID;
} bless_cache_entry;

typedef struct bless_cache_task_data_t {
  short moteID;
  short destination;
  short prev_src;
  char hops;
  char type;
} bless_task_data;

typedef struct {
  char index;
  char motes[10];
} packet_path;

extern short TOS_LOCAL_ADDRESS;

#define NUM_ENTRIES 8
#define MAX_WEIGHT 100
#define NULL 0
#define RECALC_TIMER 5   // How many times cache is updated before
                          // recalculation spawned

#define IS_VALID(entry) ((entry != 0) && ((entry)->state & 0x1))
#define MARK_VALID(entry) ((entry)->state |= 0x1)
#define MARK_INVALID(entry) ((entry)->state &= ~(0x1))

#define PING_PENDING(entry) ((entry)->state & 0x2)
#define MARK_PING(entry) ((entry)->state |= 0x2)
#define CLEAR_PING(entry) ((entry)->state &= ~(0x2))

#define NEW_ENTRY 0x1

#define TYPE_DATA 4
#define TYPE_PING 1

#define TOS_FRAME_TYPE BLESS_NEW_obj_frame
TOS_FRAME_BEGIN(BLESS_NEW_obj_frame) {
  bless_cache_entry cache[NUM_ENTRIES]; // Cache of heard mote IDs
  bless_cache_entry* cache_order[NUM_ENTRIES]; // Ordered cache
  bless_task_data task_data;            // Data for
  
  TOS_Msg data_buf;	                // A packet buffer we hand around
  TOS_MsgPtr msg;                       // Pointer to a message.

  char send_pending;                    
  char hops;
  char counter;                         // Used for resorting every few
                                        // packet events
}
TOS_FRAME_END(BLESS_NEW_obj_frame);


/* Calculate the weighted hop_count of this mote by examining the cache. */
TOS_TASK(calculateHops) {
  unsigned short hops = 0;
  int i;
  for (i = 0; i < 8; i++) {
    if (!IS_VALID(VAR(cache_order)[i])) {
      if (i == 0) {
	VAR(hops) = 255;
      }
      else { // Last entry; it counts as much as its predecessor
	bless_cache_entry* entry = VAR(cache_order)[i - 1];
	hops += (unsigned short)(entry->hops << (7 - (i - 1)));
	i = 8;
      }
    }
    else {
      bless_cache_entry* entry = VAR(cache_order)[i];
      hops += (unsigned short)(entry->hops << (7 - i));
    }
  }
  
  dbg(DBG_USR3, ("New hops: %i\n", (int)(VAR(hops))));
  
  VAR(hops) = (char)((hops >> 8) + 1);
}

TOS_TASK(resort_cache) {
  bless_cache_entry* outer;
  bless_cache_entry* inner;
  int i, j;

  dbg(DBG_USR3, ("\nBLESS: Sorting cache.\n"));
  
  for (i = 0; i < NUM_ENTRIES; i++) {
    if (VAR(cache_order)[i]->weight > 80) {
      VAR(cache_order)[i]->state &= ~(0x1); // Clear the valid bit
    }
  }

  
  for (i = 0; i < NUM_ENTRIES; i++) {
    outer = VAR(cache_order)[i];
    for (j = i + 1; j < NUM_ENTRIES; j++) {
      inner = VAR(cache_order)[j];
      if (!IS_VALID(outer) ||
	  (inner->weight < outer->weight && IS_VALID(inner))) {
	VAR(cache_order)[i] = inner;
	VAR(cache_order)[j] = outer;
	outer = inner;
      }
    }
    VAR(cache_order)[i] = outer;
  }

  // Post task to recalculate our distance
  TOS_POST_TASK(calculateHops);

  dbg_clear(DBG_USR3, ("Weight   Name   Hops    Valid?\n"));
  for (i = 0; i < NUM_ENTRIES; i++) {
    dbg_clear(DBG_USR3, ("%-9i %-6i %-7i %c\n", VAR(cache_order)[i]->weight, VAR(cache_order)[i]->moteID, VAR(cache_order)[i]->hops, IS_VALID(VAR(cache_order)[i])? 'V':'-'));
  }
}

static inline char has_parent() {
  return IS_VALID(VAR(cache_order)[0]);
}

static inline void mark_resend_heard(bless_cache_entry* entry) {
  entry->weight -= 2;

  dbg(DBG_ROUTE, ("BLESS: resend heard: %i, new weight: %i\n", entry->moteID, entry->weight));
  
  if (entry->weight < 0) {entry->weight = 0;}
  if (VAR(counter) >= RECALC_TIMER) {
    VAR(counter) = 0;
    TOS_POST_TASK(resort_cache);
  }
}

static inline void mark_ping_heard(bless_cache_entry* entry) {
  entry->weight -= 2;

  dbg(DBG_ROUTE, ("BLESS: ping heard: %i, new weight: %i\n", entry->moteID, entry->weight));

  if (entry->weight < 0) {entry->weight = 0;}
  if (VAR(counter) >= RECALC_TIMER) {
    VAR(counter) = 0;
    TOS_POST_TASK(resort_cache);
  }
}

static inline void mark_packet_sent(bless_cache_entry* entry) {
  entry->weight++;

  dbg(DBG_ROUTE, ("BLESS: packet sent to %i, new weight: %i\n", entry->moteID, entry->weight));

  if (entry->weight > MAX_WEIGHT) {MARK_INVALID(entry);}
  if (VAR(counter) >= RECALC_TIMER) {
    VAR(counter) = 0;
    TOS_POST_TASK(resort_cache);
  }
}

static inline void mark_ping_sent(bless_cache_entry* entry) {
  entry->weight++;

  dbg(DBG_ROUTE, ("BLESS: ping sent to %i, new weight: %i\n", entry->moteID, entry->weight));

  if (entry->weight > MAX_WEIGHT) {MARK_INVALID(entry);}
  if (VAR(counter) >= RECALC_TIMER) {
    VAR(counter) = 0;
    TOS_POST_TASK(resort_cache);
  }
}

static inline bless_cache_entry* getWorseEntry(char hops) {
  int i;
  bless_cache_entry* lowest = VAR(cache_order)[0];

  dbg(DBG_ROUTE, ("BLESS: Looking for a cache entry worse than %i:", (int)hops));
  
  // Look for an invalid cache entry
  for (i = (NUM_ENTRIES - 1); i >= 0; i--) {
    bless_cache_entry* entry = VAR(cache_order)[i];
    if (!IS_VALID(entry)) {
      dbg_clear(DBG_ROUTE, (" found an invalid one.\n"));
      return entry;
    }
    else if (entry->weight > lowest->weight) {
      lowest = entry;
    }
  }

  // They're all valid; check the worst one
  if (lowest->weight > ((hops << 2) + hops)) {
    dbg_clear(DBG_ROUTE, (" found the lowest valid one.\n"));
    return lowest;
  }

  //We're worst than the worst cache entry
  dbg_clear(DBG_ROUTE, (" there's nothing worse.\n"));
  return NULL; 
}

static inline void fill_cache_entry(bless_cache_entry* entry,
				    short moteID,
				    char hops) {

  dbg(DBG_ROUTE, ("BLESS: filling cache entry. %i:%i\n", (int)moteID, (int)hops));
      
  entry->moteID = moteID;
  entry->weight = (hops << 2) + hops; // hops * 5
  entry->state = NEW_ENTRY;
  entry->heard = 1;
  entry->hops = hops;
  TOS_POST_TASK(resort_cache);
}

bless_cache_entry* cache_insert(short moteID, char hops) {
  bless_cache_entry* fresh_entry;
  int i;

  dbg(DBG_ROUTE, ("BLESS: Inserting a cache entry.\n"));
  for (i = 0; i < NUM_ENTRIES; i++) {
    fresh_entry = getWorseEntry(hops);
    if (fresh_entry != NULL) {
      dbg_clear(DBG_ROUTE, ("\tGot one. Using it.\n"));
      fill_cache_entry(fresh_entry, moteID, hops);
      VAR(counter)++;
      return fresh_entry;
    }
  }
  dbg_clear(DBG_ROUTE, ("\tNo freeable cache entry.\n"));
  return NULL;
}

static inline bless_cache_entry* getEntry(short moteID) {
  int i;
  
  for (i = 0; i < NUM_ENTRIES; i++) {
    if (VAR(cache_order)[i]->moteID == moteID &&
	IS_VALID(VAR(cache_order)[i])) {
      return VAR(cache_order)[i];
    }
  }
 return NULL;
}

static inline char isInCache(short moteID) {
  if (getEntry(moteID) != NULL) {
    return 1;
  }
  else {
    return 0;
  }
}


/*
 * Picks a parent entry to use.
 *
 * Parent selection is probabilistic, using the sorted cache of entries.
 * Where 0 is the best weighted entry,
 *
 * P(n) = (P(n) - 1) / 2
 * P(0) = 50%.
 *
 * The probability distribution across the entries is exponential:
 * the best entry will be selected 50% of the time,
 * the second best 25%
 * the third best 12.5%
 * etc.
 *
 * The last valid entry in the cache has the same probability as the
 * one before it. So if there are five entries, the probabilities are:
 *
 * 0: 50%
 * 1: 25%
 * 2: 12.5%
 * 3: 6.25%
 * 4: 6.25%
 */

bless_cache_entry* pick_parent_entry(char maxHops, short source) {
  int i;
  short rand = TOS_CALL_COMMAND(BLESS_NEW_RAND)();
  bless_cache_entry* backupEntry = VAR(cache_order)[0];

  for (i = 0; i < NUM_ENTRIES; i++) {
    bless_cache_entry* entry;
    entry = VAR(cache_order)[i];
    if (!IS_VALID(entry)) {
      if (i == 0) {
	return NULL;
      }
      else {
	entry = backupEntry;
	dbg_clear(DBG_ROUTE, ("BLESS: Picking parent entry to send to: %i\n", (int)(i - 1)));
	return entry;
      }
    }
    else{
      if (VAR(cache_order)[i]->hops <= maxHops) {
	backupEntry = VAR(cache_order)[i];
      }
      if (rand & 0x1 && entry->moteID != source) { // Here's the probabilistic part
	entry = VAR(cache_order)[i];
	if (entry->hops > maxHops && backupEntry != NULL) {
	  entry = backupEntry;
	}
	dbg_clear(DBG_ROUTE, ("BLESS: Picking parent entry to send to: %i\n", (int)(i)));
	return entry;
      }
    }
    rand = rand >> 1;
  }
  dbg_clear(DBG_ROUTE, ("BLESS: Picking parent entry to send to: %i\n", (int)(NUM_ENTRIES - 1)));
  return VAR(cache_order)[NUM_ENTRIES - 1];
}

void update_cache_entry(bless_cache_entry* entry) {
  dbg(DBG_ROUTE, ("Updating cache entry for %i\n", (int)entry->moteID));
  
  // Update entry weight if it's a ping response
  if (VAR(task_data).type == TYPE_PING &&
      PING_PENDING(entry)) {
    VAR(counter)++;
    mark_ping_heard(entry);
  }
  // Update entry weight if it's a data forwarding
  else if (VAR(task_data).type == TYPE_DATA &&
	   VAR(task_data).prev_src == TOS_LOCAL_ADDRESS) {
    VAR(counter)++;
    mark_resend_heard(entry);
  }
  
  // If entry has new hop count, adjust weight
  if (VAR(task_data).hops != entry->hops) {
    char diff = VAR(task_data).hops - entry->hops;
    diff = (diff << 2) + diff;
    entry->weight += diff;
    dbg(DBG_ROUTE, ("BLESS: entry has new hop count, adjusting %i weight to %i\n", entry->moteID, entry->weight));
    
    VAR(counter)++;
  }
}


TOS_TASK(cache_task) {
  bless_cache_entry* entry;

  dbg(DBG_ROUTE, ("BLESS_NEW: Running cache task.\n"));
  dbg_clear(DBG_ROUTE, ("      entry: %i->%i->%i %i (T:%i)\n",
			VAR(task_data).prev_src,
			VAR(task_data).moteID,
			VAR(task_data).destination,
			VAR(task_data).hops,
			VAR(task_data).type));
  
  entry = getEntry(VAR(task_data).moteID);

  if (entry != NULL) {
    update_cache_entry(entry);
  }
  else {
    cache_insert(VAR(task_data).moteID, VAR(task_data).hops);
  }
}

char TOS_COMMAND(BLESS_NEW_INIT)(){
  int i;
  TOS_CALL_COMMAND(BLESS_NEW_SUB_INIT)();

  for (i = 0; i < NUM_ENTRIES; i++) {
    VAR(cache_order)[i] = &(VAR(cache)[i]);
    MARK_INVALID(VAR(cache_order)[i]);
  }
  
  VAR(msg) = &VAR(data_buf);
  VAR(counter) = 0;
  VAR(hops) = 127;
  VAR(send_pending) = 0;
  return 1;
}

char TOS_COMMAND(BLESS_NEW_START)(){
  //TOS_CALL_COMMAND(BLESS_NEW_SUB_PING)(TOS_BCAST_ADDR, 0);
  return 1;
}

// Returns whether the node is network-active (sending packets)
char TOS_COMMAND(BLESS_NEW_ACTIVE)() {
  return has_parent();
}

char TOS_COMMAND(BLESS_NEW_SEND)(char* data, char len) {
  bless_msg* b_message = (bless_msg*)&(VAR(data_buf).data);
  bless_cache_entry* entry = pick_parent_entry(VAR(hops), TOS_LOCAL_ADDRESS);
  packet_path* path = (packet_path*)&(b_message->data);
  
  if (VAR(send_pending) != 0 || entry == NULL || TOS_LOCAL_ADDRESS == 0){
    return 0;
  }
  path->index = 0;
  path->motes[(int)path->index] = (char)TOS_LOCAL_ADDRESS;
  path->index++;

  b_message->dest = entry->moteID;
  b_message->hop_src = TOS_LOCAL_ADDRESS;
  b_message->src = TOS_LOCAL_ADDRESS;
  b_message->prev_src = TOS_LOCAL_ADDRESS;
  b_message->src_hop_distance = VAR(hops);
  b_message->count = VAR(hops) + 2;
  
  if (TOS_CALL_COMMAND(BLESS_NEW_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(DATA_MSG),&VAR(data_buf))) {
    mark_packet_sent(entry);
    dbg(DBG_ROUTE, ("BLESS_NEW sending data of length %i\n", len));
    VAR(send_pending) = 1;
  }
  return 1;
}


TOS_MsgPtr TOS_MSG_EVENT(DATA_MSG)(TOS_MsgPtr msg){
  bless_msg* b_message = (bless_msg*)msg->data;
  packet_path* path = (packet_path*)b_message->data;

  // Store info about this packet
  VAR(task_data).moteID = b_message->hop_src;
  VAR(task_data).hops = b_message->src_hop_distance;
  VAR(task_data).destination = b_message->dest;
  VAR(task_data).prev_src = b_message->prev_src;
  VAR(task_data).type = TYPE_DATA;
    
  dbg(DBG_ROUTE, ("BLESS_NEW received message.\n"));

  // If we're the next hop, forward if we can
  if (b_message->dest == TOS_LOCAL_ADDRESS) {
    int i;

    if (TOS_LOCAL_ADDRESS == 0 && VAR(send_pending) == 0) {
      int i;
      bless_msg* new_message = (bless_msg*)VAR(msg)->data;
      
      dbg(DBG_USR2, ("PATH: "));
      for (i = 0; i < path->index; i++) {
	dbg_clear(DBG_USR2, ("%i->", (int)path->motes[i]));
      }
            
      VAR(send_pending) = 1;
      new_message->dest = TOS_LOCAL_ADDRESS;
      new_message->prev_src = b_message->hop_src;
      new_message->src_hop_distance = 0;
      
      dbg(DBG_ROUTE, ("BLESS_NEW: Forwarding packet from %i to %i\n", new_message->src, new_message->dest));
      
      if(TOS_CALL_COMMAND(BLESS_NEW_SUB_SEND_MSG)(TOS_BCAST_ADDR,
						  AM_MSG(DATA_MSG),
						  VAR(msg))) {
	dbg_clear(DBG_USR2, ("%i\n", (int)TOS_LOCAL_ADDRESS));
      }
      else {
	dbg_clear(DBG_USR2, ("%i->|\n", (int)TOS_LOCAL_ADDRESS));
	VAR(send_pending) = 0;
      }
    }
    else {
      bless_cache_entry* fwd = pick_parent_entry(b_message->count, b_message->hop_src);
      if (fwd != NULL && VAR(send_pending) == 0) {
	int i;
	bless_msg* new_message = (bless_msg*)&(VAR(data_buf).data);
	packet_path* new_path = (packet_path*)&(new_message->data);

	VAR(send_pending) = 1;
	new_message->dest = fwd->moteID;
	new_message->src = b_message->src;
	new_message->prev_src = b_message->hop_src;
	new_message->hop_src = TOS_LOCAL_ADDRESS;
	new_message->src_hop_distance = VAR(hops);
	new_message->count = b_message->count - 1;

	new_path->index = (path->index + 1);
	for (i = 0; i < path->index; i++) {
	  new_path->motes[i] = path->motes[i];
	}
	new_path->motes[(int)path->index] = (char)(TOS_LOCAL_ADDRESS & 0xff);
      
	dbg(DBG_ROUTE, ("BLESS_NEW: Forwarding packet from %i to %i\n", new_message->src, new_message->dest));
	
	if(TOS_CALL_COMMAND(BLESS_NEW_SUB_SEND_MSG)(TOS_BCAST_ADDR,
						    AM_MSG(DATA_MSG),
						    &VAR(data_buf))) {
	  mark_packet_sent(fwd);
	}
	else {
	  VAR(send_pending) = 0;
	}
      }
      else {
	dbg(DBG_ROUTE, ("BLESS_NEW: We can't forward: no parents available!\n"));
      }
    }
  }
  if (VAR(task_data).moteID != TOS_LOCAL_ADDRESS) {
    TOS_POST_TASK(cache_task);
  }
  
  return msg;
}


char TOS_EVENT(BLESS_NEW_SEND_DONE)(TOS_MsgPtr data){
  VAR(send_pending) = 0;
  return 1;
}

char TOS_EVENT(BLESS_PING_RECEIVE)(short moteID, char sequence) {
  TOS_CALL_COMMAND(BLESS_NEW_SUB_PING)(TOS_BCAST_ADDR, sequence + 1);
  dbg(DBG_USR1, ("Received PING broadcast.\n"));
  cache_insert(moteID, sequence);
  TOS_POST_TASK(resort_cache);
  return 0;
}

char TOS_EVENT(BLESS_PING_RESPONSE)(short moteID, char sequence) {
  return 1;
}

