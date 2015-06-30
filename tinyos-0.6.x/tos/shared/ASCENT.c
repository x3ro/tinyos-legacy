/*									tab:4
 * ASCENT.c
 *
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors: Thanos Stathopoulos 
 * Original concept: Alberto Cerpa
 *
 * Use the following compiler flags to activate ascent support in an
 * application:
 * -DUSE_ASCENT: Use sequence numbers in MSG.h
 * -DSB_DBG: enables serial debug mode. Note: ASCENT_DUMP message is disabled 
 * -DREAL_SLEEP: turns off radio when sleeping. 
 * -DDISABLE_ACTIVE: disables transition from test to active state 
 * -DDISABLE_ASCENT_LEDS: turns off ascent-specific LED blinking
 * -DUSE_DIFFUSION: use diffusion as the routing component
 * -DUSE_UART_AGGRESIVELY: dump state on every event (timer, RX, TX)
 *
 * NOTICE: ASCENT needs sequence numbers in the packet header to operate
 * correctly. The current TOS Msg doesn't provide this functionality. Until
 * this issue is resolved, either modify MSG.h (add a 'uint16_t seq' before
 * the DATA part of struct MSG_VALS), or omit the USE_ASCENT flag when
 * compiling. The sample application, ascent_chirp doesn't define USE_ASCENT
 * at the moment.
 * Moreover, there seems to be a conflict with the new stack's use of timer1
 * and TIMER_HEAP. Deepak is working on a solution at the moment, but, until
 * then, all timer values should be divided by 8 (i.e. timer1ps is actually
 * timer8ps, since the radio stack prescales the timer to CLK, not CLK/8).
 * 
*/


#include "tos.h"
#include "ASCENT.h"
#include <inttypes.h>
#include <string.h>
#include "ascent_msgs.h"

/* TODO: Make this better */
#ifdef USE_DIFFUSION
#include "../../apps/diffusion_sensor/DIFFNODE.inc"
#include "../../apps/diffusion_sensor/DiffNodeInc/DataMessage.inc"
#endif // USE_DIFFUSION


#ifndef SP_DBG
#define udb_init(x)
#define udb_byte(x)
#else
void udb_byte(unsigned char data);
void udb_init(unsigned char bandwidth);
#endif // SP_DBG     


/* state machine definitions */
#define STATE_NULL		0
#define STATE_TEST		1
#define STATE_ACTIVE	2
#define STATE_PASSIVE	3
#define STATE_SLEEP		4

/* Thresholds */
#define NT				3	/* Neighbor threshold */
#define LT				30	/* Loss threshold */
#define MAX_NODES		32	/* Maximum number of nodes */
#define MAX_PATHS		4	/* Maximum number of data paths */

/* Timers, in tens of seconds (referenced to 10*timer1ps) */
/* 10 seconds is the diffusion transmission rate. If it changes, timers
 * will change too
*/
#ifndef DIFF_RATE
#define DIFF_RATE 1
#endif
#define TIMER_TEST		20	
#define TIMER_PASSIVE	50	
#define TIMER_SLEEP		5
#define TIMER_CLEANUP	300
#define TIMER_AA		timer1ps+timer2ps		// TODO: Refine this
#define TIMER_AH		timer4ps+timer16ps	
#define MAX_AA			3	
#define MAX_AH			3


/* UART DUMP CALLERS */
#define TX				1
#define RX				2
#define TIMER_N			30
#define TIMER_T			31
#define TIMER_P			32
#define TIMER_S			33
#define TIMER_C			34
#define EXPLICIT		4


/* Structure used for both link and data rate loss*/
struct loss {
    uint16_t seq;					/* last sequence num received */
    uint32_t vector;                /* vector for calculating loss */
    uint8_t lossrate;
	uint8_t window_size;			/* used as the divisor in loss calcs */
	char is_neighbor;
	char recv_announcement;
	char isnot_idle;				/* 0: active, 1: idle */
	/* Add everything else ABOVE this line. pkt_cnt MUST be the last element
	*/ 
	uint16_t pkt_cnt;				/* Number of packets received */	
};

extern short TOS_LOCAL_ADDRESS;

static inline char send_ascent_packet(uint8_t type);
static inline uint8_t resolve_neighbor_clash();
static inline void statemachine();
void null_timer_expired();
void test_timer_expired();
void passive_timer_expired();
void sleep_timer_expired();
void cleanup_timer_expired();
void aatimer_expired();
void ahtimer_expired();
static inline void turn_off_radio();
static inline void turn_on_radio();
static inline void turn_off_leds();
static inline void turn_on_leds();
static inline void flip_tx_led();
void flip_rx_led();
static inline void flip_error_led();
static inline void link_level_loss_rate(uint8_t i, uint16_t current_seq);
static inline void data_level_loss_rate(uint8_t i, uint16_t current_seq);
static inline void activate_timer();
static inline void delete_test_timer();
static inline void delete_passive_timer();
static inline void create_dump_msg(struct dump_msg *msg);
static inline void clean_wakeup();
TOS_TASK(ASCENT_UART_DUMP);


#define TOS_FRAME_TYPE ASCENT_frame
TOS_FRAME_BEGIN(ASCENT_frame) {
	char state;			/* current state */

	char recv_announcement;		
	uint8_t neighbors;			
	uint8_t lastAnnouncementID;
	char help_received;			
	uint8_t pot;
	
	// All loss values are multiplied by 100 and rounded down to avoid floats
	uint8_t nlt;				/* neighbor loss threshold*/	
	uint8_t data_loss;
	uint8_t data_loss_T;		/* data loss before entering test state */	
	uint16_t seq_sent;			/* Sequence number to be put in the next */
								/* outgoing packet */
	
#ifdef USE_DIFFUSION	
	uint8_t diff_sender;		/* Diffusion-specific variables */
	uint16_t diff_seqnum;
	DataMessage* diffMsg;
#endif

	struct loss node[MAX_NODES];	/* Array used to calculate */
									/* link level loss rate */	

	struct loss path[MAX_PATHS];		/* Array used to calculate */
										/* data level loss rate */

	/* expiration check variables */
	char Tt_expired;
	char Tp_expired;
	char Ts_expired;
	char Tn_expired;

	/* Timers and related variables */
	Timer Tn;
	Timer Tt;
	Timer Tp;
	Timer Ts;
	Timer Taa;			// interval between ascent announcements
	Timer Tah;			// interval between help messages
	Timer Tc;			// cleanup timer

	uint32_t timer_test;
	uint16_t tt;
	uint32_t timer_passive;
	uint16_t tp;
	uint32_t timer_sleep;
	uint16_t ts;
	uint32_t timer_aa;
	uint8_t taa;
	uint32_t timer_ah;
	uint8_t tah;

	/* TOS messages, for the data, control and uart */
	TOS_Msg pkt;
	TOS_Msg ascent_pkt;
	TOS_Msg uart_pkt;
	TOS_Msg data;

	/* Neighbor and loss thresholds */	
	uint8_t nt;
	uint8_t lt;

	/* Counters */
	uint8_t aa_count;	/* announcement messages counter */
	uint8_t ah_count;	/* help messages counter */
	uint8_t aa_max;		/* Maximum number of announcements to be sent */	
	uint8_t ah_max;		/* Maximum number of help messsages to be sent */

	uint8_t tcount;		/* Number of times at test state */
	uint8_t pcount; 	/* Number of times at passive state */
	uint8_t scount;		/* Number of times at sleep state */

	uint8_t hcount;		/* Number of help messages received */
	uint8_t acount;		/* Number of announcements received */


	/* UART DUMP buffer variables */
	uint8_t rx_addr;
	uint8_t rx_type;	
	uint16_t rx_seqnum;
	uint8_t tx_type;
	// seq_sent is the last tx sequence number

	/* Misc variables */	
	char send_pending;	/* Variable to store state of buffer*/
	char rx_led_state;
	char tx_led_state;
	char error_led_state;

	char data_to_radio_busy;
	char uart_to_host_busy;
	
	char control_packet;
	char aa_task_posted;
	char ah_task_posted;
	char just_started;
	
	uint8_t uart_dump_caller;

	uint8_t dataaddr;
	uint16_t dataseq;	
	uint8_t vector_size;	/* size of the vector in the loss struct */

	uint32_t random;
	
	/* semaphore used for timer tasks that are pending 
	 * Every time a timer call fails, semaphore is incremented 
	 * However, semaphore is not incremented for multiple failures of
	 * the same timer call
	 * semaphore is decremented when a timer call succeeds
	 * statemachine() can only be posted when semaphore <=0 
	*/
	uint8_t timer_sema;
	
}
TOS_FRAME_END(ASCENT_frame);


/* TASKS */
/* Timer tasks */
TOS_TASK(ASCENT_CLEANUP_TIMER_TASK)

{
	if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
		(&VAR(Tc), TIMER_CLEANUP*timer1ps)==0) {
			TOS_POST_TASK(ASCENT_CLEANUP_TIMER_TASK);
	} else {
#ifdef USE_UART_AGGRESIVELY
		VAR(uart_dump_caller)=35;
		TOS_POST_TASK(ASCENT_UART_DUMP);
#endif // U_U_A
	}
}


TOS_TASK(ASCENT_NULL_TIMER_TASK)
{
	VAR(random)=TOS_CALL_COMMAND(ASCENT_RAND)();
	VAR(random)=(VAR(random)<<7);
	if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
		(&VAR(Tn), VAR(random)+timer1ps) == 0) {
		TOS_POST_TASK(ASCENT_NULL_TIMER_TASK);
	} else {
		/* note that the semaphore was not incremented on the failure.
		 * the reason is that it has already been incremented, if this
		 * task is executed. So incrementing it again for the _same_ timer
		 * doesn't help.
		*/
		VAR(timer_sema)--;                                                          }
}      

 
TOS_TASK(ASCENT_TEST_TIMER_TASK)
{
	VAR(random)=TOS_CALL_COMMAND(ASCENT_RAND)();
	VAR(random)=(VAR(random)<<11);
	if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
		(&VAR(Tt), VAR(timer_test)+VAR(random)) == 0) {
		TOS_POST_TASK(ASCENT_TEST_TIMER_TASK);
	} else {
		VAR(timer_sema)--;
	}
}

TOS_TASK(ASCENT_PASSIVE_TIMER_TASK)
{
	VAR(random)=TOS_CALL_COMMAND(ASCENT_RAND)();
	VAR(random)=VAR(random)<<12;
	if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
		(&VAR(Tp), VAR(timer_passive)+VAR(random)) == 0) {
		TOS_POST_TASK(ASCENT_PASSIVE_TIMER_TASK);                          
	} else {
		VAR(timer_sema)--;
	}  
}       

TOS_TASK(ASCENT_SLEEP_TIMER_TASK)
{
	VAR(random)=TOS_CALL_COMMAND(ASCENT_RAND)();
	VAR(random)=VAR(random)<<14;
	if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
		(&VAR(Ts), VAR(timer_sleep)+VAR(random)) == 0) {
		TOS_POST_TASK(ASCENT_SLEEP_TIMER_TASK);                         
	} else {
		VAR(timer_sema)--;
	}
}     

 
TOS_TASK(ASCENT_AATIMER_TASK)
{
	VAR(random)=TOS_CALL_COMMAND(ASCENT_RAND)();
	VAR(random)=VAR(random)<<5;
	if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
		(&VAR(Taa), VAR(timer_aa)+VAR(random)) == 0) {
		// Repost on error
		TOS_POST_TASK(ASCENT_AATIMER_TASK);
	}
}

/* Ascent Help timer task */
TOS_TASK(ASCENT_AHTIMER_TASK)
{
	VAR(random)=TOS_CALL_COMMAND(ASCENT_RAND)();
	VAR(random)=VAR(random)<<4;
	if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
		(&VAR(Tah), VAR(timer_ah)+VAR(random)) == 0) {
		// Repost on error
		TOS_POST_TASK(ASCENT_AHTIMER_TASK);
	}
}           	

/* Self explanatory */
TOS_TASK(ASCENT_DEL_TEST_TIMER_TASK)
{
	if (TOS_CALL_COMMAND(ASCENT_DEL_TIMER)(&VAR(Tt))==0) {
		VAR(timer_sema)++;
		TOS_POST_TASK(ASCENT_DEL_TEST_TIMER_TASK);
	} else {
		VAR(timer_sema)--;
	}
}	

TOS_TASK(ASCENT_DEL_PASSIVE_TIMER_TASK)
{
	if (TOS_CALL_COMMAND(ASCENT_DEL_TIMER)(&VAR(Tp))==0) {
		VAR(timer_sema)++;
		TOS_POST_TASK(ASCENT_DEL_PASSIVE_TIMER_TASK);
	} else {
		VAR(timer_sema)--;
	}
}


TOS_TASK(ASCENT_DEL_AATIMER_TASK)
{
	TOS_CALL_COMMAND(ASCENT_DEL_TIMER)(&VAR(Taa));
	VAR(aa_count)=0;
	VAR(aa_task_posted)=0;
}


TOS_TASK(ASCENT_DEL_AHTIMER_TASK)
{
	TOS_CALL_COMMAND(ASCENT_DEL_TIMER)(&VAR(Tah));
	VAR(ah_count)=0;
	VAR(ah_task_posted)=0;
}	


/* State machine task */
TOS_TASK(ASCENT_STATEMACHINE)
{
	if (VAR(timer_sema)<=0)
		statemachine();
}


TOS_TASK(ASCENT_COUNT_NEIGHBORS)
{
	uint8_t i=0;
	VAR(neighbors)=0;
	for (i=1;i<MAX_NODES;i++) {
		if (VAR(node)[i].is_neighbor==1) {	
			VAR(neighbors)++;
		}
	}
	TOS_POST_TASK(ASCENT_STATEMACHINE);
}


/* UART Xmit task */
TOS_TASK(ASCENT_UART_DUMP)
{
	if (VAR(uart_to_host_busy)==1) {
//		flip_error_led();	
		return;
	}
	memset(&VAR(uart_pkt), 0, sizeof(struct MSG_VALS));
	VAR(uart_pkt).type=ASCENT_DUMP;
	VAR(uart_pkt).addr=TOS_LOCAL_ADDRESS;
	VAR(uart_pkt).group=DEFAULT_LOCAL_GROUP;
#ifdef USE_ASCENT
	VAR(uart_pkt).seq=0x0000;
#endif
	create_dump_msg((struct dump_msg *)(VAR(uart_pkt).data));
#ifndef SP_DBG
	if (TOS_CALL_COMMAND(ASCENT_UART_TX_PACKET)(&(VAR(uart_pkt))) == 1) {
		VAR(uart_to_host_busy)=1;
	} 

#endif
	return;	 
}


/* Loss rate calculating tasks */
/* Link level loss rate */
TOS_TASK(ASCENT_LLLR)
{
#ifdef USE_ASCENT
	link_level_loss_rate(VAR(dataaddr), VAR(dataseq));
#endif
}


/* Data level loss rate */
/* Not implemented yet */
TOS_TASK(ASCENT_DLLR)
{
#ifdef USE_DIFFUSION
	uint8_t i=0;
	/* Hash the sender using mod MAX_PATHS */
	i=VAR(diff_sender) & (MAX_PATHS-1);
	if (i<MAX_PATHS)
		data_level_loss_rate(i, VAR(diff_seqnum));
		
#endif
}





/* ASCENT_INIT: */ 
char TOS_COMMAND(ASCENT_INIT)()
{
	uint8_t i;
	udb_init(12);
	udb_byte(100);                 
	TOS_CALL_COMMAND(ASCENT_SUB_INIT)();	/* initialize lower components */
	TOS_CALL_COMMAND(ASCENT_UART_INIT)();
#ifndef USE_DIFFUSION
	TOS_CALL_COMMAND(ASCENT_POT_INIT)(20);
#endif
	TOS_CALL_COMMAND(ASCENT_TIMER_INIT)();

	VAR(neighbors)=0;
	VAR(data_loss)=0;
	VAR(data_loss_T)=0;
	VAR(data_to_radio_busy)=0;

	VAR(state) = STATE_NULL;

	initTimer(&VAR(Tn));
	initTimer(&VAR(Tt));
	initTimer(&VAR(Tp));
	initTimer(&VAR(Ts));
	initTimer(&VAR(Tc));
	setAperiodic(&VAR(Tn));
	setAperiodic(&VAR(Tt));
	setAperiodic(&VAR(Tp));
	setAperiodic(&VAR(Ts));

	setPeriodic(&VAR(Tc), TIMER_CLEANUP*timer1ps);

	VAR(Tn).f=null_timer_expired;
	VAR(Tt).f=test_timer_expired;
	VAR(Tp).f=passive_timer_expired;
	VAR(Ts).f=sleep_timer_expired;

	VAR(Tc).f=cleanup_timer_expired;

	initTimer(&VAR(Taa));
	setAperiodic(&VAR(Taa));	
	VAR(Taa).f=aatimer_expired;
//	VAR(Taa).periodic_offset=TIMER_AA;
	initTimer(&VAR(Tah));
	setAperiodic(&VAR(Tah));
	VAR(Tah).f=ahtimer_expired;

	VAR(nt) = NT;
	VAR(lt) = LT;
	VAR(tt)= TIMER_TEST;
	VAR(tp)= TIMER_PASSIVE;
	VAR(ts)= TIMER_SLEEP;

	VAR(timer_test)=VAR(tt)*DIFF_RATE*timer1ps;
	VAR(timer_passive)=VAR(tp)*DIFF_RATE*timer1ps;
	VAR(timer_sleep)=VAR(ts)*DIFF_RATE*timer1ps;
	VAR(timer_aa)=TIMER_AA;
	VAR(timer_ah)=TIMER_AH;

	VAR(aa_max)=MAX_AA;
	VAR(ah_max)=MAX_AH;

	VAR(just_started)=1;
	/* vector size: sizeof (variable), in bytes, multiplied by 8 (2^3) */
	VAR(vector_size)=sizeof(VAR(node)[0].vector) << 3;

	VAR(random)=TOS_CALL_COMMAND(ASCENT_RAND)();
	VAR(random)=(VAR(random)<<6);

/* If I don't fill the data part of a packet with DIFFERENT values, it
 * has a VERY HIGH probability of being dropped due to crc errors. No
 * reasons why this is happening, at this time, especially when motenic
 * is receiving the packet anyway!
*/    
	for (i=0;i<DATA_LENGTH;i++) {
		VAR(ascent_pkt).data[i]=(i+1);                                  
	} 


//	TOS_POST_TASK(ASCENT_CLEANUP_TIMER_TASK);		
	TOS_POST_TASK(ASCENT_STATEMACHINE);
//	statemachine();
	return 1;
}




/* This is the state machine of ASCENT. All state changes take place here */
static inline void statemachine()
{
	udb_byte(255);
	switch(VAR(state)) {
		case STATE_NULL:
			if (VAR(Tn_expired)==1) {
				VAR(state)=STATE_TEST;
				VAR(tcount)++;
				activate_timer();
//#ifndef DISABLE_ASCENT_LEDS
				CLR_RED_LED_PIN();
//#endif // D_A_L

				/* The following task sends ascent announcements */
				if (send_ascent_packet(ASCENT_ANNOUNCEMENT)==1)
					VAR(aa_count)=1;
				TOS_POST_TASK(ASCENT_AATIMER_TASK); 
	
				VAR(Tt_expired)=0;
			} else {
				activate_timer();
			}
			break;	
		case STATE_TEST:
			if (VAR(Tt_expired)==1) {
#ifdef DISABLE_ACTIVE
				VAR(state)=STATE_PASSIVE;		//TODO: CHANGE THAT!

				VAR(pcount)++;

//				turn_off_leds();
//				CLR_RED_LED_PIN();
//				CLR_GREEN_LED_PIN();

				VAR(Tp_expired)=0;
				activate_timer();

#else
				VAR(state)=STATE_ACTIVE;
				turn_off_leds();
#endif
				break;
			}
			if	(VAR(neighbors)>VAR(nt)) {  
				/* There is a potential tricky situation 
				 * when two or more nodes compete.
				 * A tie-braking mechanism is needed.
				*/
				if (resolve_neighbor_clash()==0) {
					VAR(state)=STATE_PASSIVE;
					turn_off_leds();
#ifndef DISABLE_ASCENT_LEDS
					CLR_RED_LED_PIN();
					CLR_GREEN_LED_PIN();
#endif //D_A_L
					VAR(pcount)++;
					VAR(Tt_expired)=0;
					VAR(Tp_expired)=0;
					if (isFree(&VAR(Tt))==0) {
						delete_test_timer();
					}
					activate_timer();
					break;
				}	
			} else if ((VAR(data_loss) > VAR(data_loss_T)) 
						&& VAR(just_started)==0) {
				/* Choice is clear, go passive */
#ifndef DISABLE_ASCENT_LEDS
				turn_off_leds();
				CLR_RED_LED_PIN();
				CLR_GREEN_LED_PIN();
#endif //D_A_L
				VAR(state)=STATE_PASSIVE;
				VAR(pcount)++;
				VAR(Tt_expired)=0;
				VAR(Tp_expired)=0;
				if (isFree(&VAR(Tt))==0) {
					delete_test_timer();
				}
				activate_timer();
				udb_byte(222);
				break;
			} else if ((VAR(data_loss) > VAR(lt)) && VAR(just_started)==1) {
				VAR(just_started)=0;
#ifndef DISABLE_ASCENT_LEDS
				turn_off_leds();
				CLR_RED_LED_PIN();
				CLR_GREEN_LED_PIN();
#endif //D_A_L
				VAR(state)=STATE_PASSIVE;	
				VAR(pcount)++;
				VAR(Tt_expired)=0;
				VAR(Tp_expired)=0;
				if (isFree(&VAR(Tt))==0) {
					delete_test_timer();
				}
				activate_timer();
				udb_byte(VAR(state));
				udb_byte(111);
				break;
			}
			break;
		case STATE_PASSIVE:
			if (VAR(Tp_expired)==1) {
				VAR(state)=STATE_SLEEP;
				VAR(scount)++;
				turn_off_radio();
#ifndef DISABLE_ASCENT_LEDS
				turn_off_leds();
				CLR_GREEN_LED_PIN();	// XXX
#endif //D_A_L
				VAR(Ts_expired)=0;
				activate_timer();
				break;
			}
			if (VAR(neighbors) <= VAR(nt)) {
/* If diffusion is in use, ASCENT behaves as stated in the protocol */
#ifdef USE_DIFFUSION
				if (VAR(data_loss) > VAR(lt)) {
					VAR(data_loss_T)=VAR(data_loss);
					VAR(state)=STATE_TEST;
					VAR(tcount)++;
#ifndef DISABLE_ASCENT_LEDS
					turn_off_leds();		// XXX
					CLR_RED_LED_PIN();
#endif // D_A_L
					VAR(Tp_expired)=0;
					VAR(Tt_expired)=0;
					if (isFree(&VAR(Tp))==0) {
						delete_passive_timer();
					}
					activate_timer();
					if (send_ascent_packet(ASCENT_ANNOUNCEMENT)==1)
						VAR(aa_count)=1;
					TOS_POST_TASK(ASCENT_AATIMER_TASK); 
					break;
				} 
				if ((VAR(data_loss) <= VAR(lt))
					 && (VAR(help_received)==1)) {
					VAR(data_loss_T)=VAR(data_loss);
					VAR(state)=STATE_TEST;
					VAR(tcount)++;
					VAR(help_received)=0;
#ifndef DISABLE_ASCENT_LEDS
					turn_off_leds();		// XXX
					CLR_RED_LED_PIN();
#endif
					VAR(Tp_expired)=0;
					VAR(Tt_expired)=0;
					if (isFree(&VAR(Tp))==0) {
						delete_passive_timer();
					}
					activate_timer();
					if (send_ascent_packet(ASCENT_ANNOUNCEMENT)==1)
						VAR(aa_count)=1;
					TOS_POST_TASK(ASCENT_AATIMER_TASK); 
					break;
				}
/* If diffusion is not in use, ASCENT switches state 
 * if neighbors <= neighbor threshold
*/
#else
				VAR(state)=STATE_TEST;
#ifndef DISABLE_ASCENT_LEDS
				turn_off_leds();
				CLR_RED_LED_PIN();
#endif
				VAR(tcount)++;
				VAR(Tp_expired)=0;
				VAR(Tt_expired)=0;
				if (isFree(&VAR(Tp))==0) {
					delete_passive_timer();
				}
				activate_timer();
				if (send_ascent_packet(ASCENT_ANNOUNCEMENT)==1)
					VAR(aa_count)=1;
				TOS_POST_TASK(ASCENT_AATIMER_TASK);
				break;
#endif // USE_DIFFUSION
			}	
			break;
		case STATE_SLEEP:
			if (VAR(Ts_expired)==1) {
				clean_wakeup();
				VAR(state)=STATE_PASSIVE;
				VAR(pcount)++;
#ifndef DISABLE_ASCENT_LEDS
				turn_off_leds();		//XXX
				CLR_RED_LED_PIN();
				CLR_GREEN_LED_PIN();	
#endif // D_A_L
				turn_on_radio();
				VAR(Tp_expired)=0;
				activate_timer();
				break;
			}
			break;
		case STATE_ACTIVE:
			/* Ask for help if data loss > loss threshold */

			if (VAR(data_loss) > VAR(lt)) {
//				if (send_ascent_packet(ASCENT_HELP)==1) {
//					VAR(ah_count)++;
//				}
			}	
//				TOS_POST_TASK(ASCENT_AHTIMER_TASK);	

			break;
		default:
//			flip_error_led();
			break;
	}
}
			

/* Timer expired callbacks */
void null_timer_expired()
{
	VAR(Tn_expired)=1;
	TOS_POST_TASK(ASCENT_STATEMACHINE);
	VAR(uart_dump_caller)=TIMER_N;
	udb_byte(101);

#ifdef USE_UART_AGGRESIVELY
	TOS_POST_TASK(ASCENT_UART_DUMP);	
#endif
}


void test_timer_expired()
{
	VAR(Tt_expired)=1;
	TOS_POST_TASK(ASCENT_STATEMACHINE);
	VAR(uart_dump_caller)=TIMER_T;
	
#ifdef USE_UART_AGGRESIVELY
	TOS_POST_TASK(ASCENT_UART_DUMP);
#endif
}


void passive_timer_expired()
{
	VAR(Tp_expired)=1;
	TOS_POST_TASK(ASCENT_STATEMACHINE);
	VAR(uart_dump_caller)=TIMER_P;

#ifdef USE_UART_AGGRESIVELY
	TOS_POST_TASK(ASCENT_UART_DUMP);
#endif
}


void sleep_timer_expired()
{
	VAR(Ts_expired)=1;
	TOS_POST_TASK(ASCENT_STATEMACHINE);
	VAR(uart_dump_caller)=TIMER_S;

#ifdef USE_UART_AGGRESIVELY
	TOS_POST_TASK(ASCENT_UART_DUMP);
#endif
}


/* Callback for the ascent announcement timer */
void aatimer_expired() 
{
	if ((VAR(aa_count)>=VAR(aa_max)) || (VAR(state)==STATE_PASSIVE)
		|| (VAR(state)==STATE_SLEEP)) {
/*
		if (VAR(aa_task_posted)==0) {
			TOS_POST_TASK(ASCENT_DEL_AATIMER_TASK);
			VAR(aa_task_posted)=1;

		}
*/
		return;
	}
	if (send_ascent_packet(ASCENT_ANNOUNCEMENT)==1)
		VAR(aa_count)++;
	TOS_POST_TASK(ASCENT_AATIMER_TASK);
}	
	
/* Callback for the ascent help timer */
/* Currently unused */
void ahtimer_expired()
{
	if (VAR(ah_count)>=VAR(ah_max)) {
/*
		if (VAR(ah_task_posted)==0) {
			TOS_POST_TASK(ASCENT_DEL_AHTIMER_TASK);
			VAR(ah_task_posted)=1;	
		}
*/
		return;
	}
	if (send_ascent_packet(ASCENT_HELP)==1)
		VAR(ah_count)++;
}	
	
/* Callback for the cleanup timer */
/* The cleanup timer will run every X minutes and check the entire node list
 * if it sees that a node has been idle since the last invocation of the
 * callback function, it will clear the node's is_neigbor flag. 
 * It will also mark every node as idle regardless of previous state (so that
 * the next invocation can check whether the node was idle for X minutes or
 * not). The isnot_idle flag is set to 1 every time a packet is received from
 * that particular node
*/ 
void cleanup_timer_expired()
{
	uint8_t i;
	for (i=0; i<MAX_NODES; i++) {
		if (VAR(node)[i].isnot_idle==0) {
			VAR(node)[i].is_neighbor=0;
		} else {
			VAR(node)[i].isnot_idle=0;
		}
	}
#ifdef USE_UART_AGGRESIVELY
	VAR(uart_dump_caller)=TIMER_C;
	TOS_POST_TASK(ASCENT_UART_DUMP);
#endif // U_U_A
		
	TOS_POST_TASK(ASCENT_COUNT_NEIGHBORS);
}

/* Radio control */
/* Radio is really off only when REAL_SLEEP is defined. 
 * Otherwise, the RX event just rejects all packets received
 * This is done for debugging purposes
*/
static inline void turn_off_radio()
{
#ifdef REAL_SLEEP
	CLR_RFM_CTL0_PIN();
	CLR_RFM_CTL1_PIN();
	CLR_RFM_TXD_PIN();
#endif
	return;
}


static inline void turn_on_radio()	
/* Puts radio in receive mode */
/* Made obsolete by new stack */
{
//	TOS_CALL_COMMAND(ASCENT_RFM_INIT)();
}


/* LEDs */
static inline void flip_tx_led()
{
#ifndef DISABLE_ASCENT_LEDS
/*
	if (VAR(tx_led_state)==0)
		CLR_RED_LED_PIN();
	else
		SET_RED_LED_PIN();
	VAR(tx_led_state)= ! VAR(tx_led_state);
*/
#endif
}


void flip_rx_led()
{
#ifndef DISABLE_ASCENT_LEDS

    if (VAR(rx_led_state)==0)
        CLR_GREEN_LED_PIN();
    else
        SET_GREEN_LED_PIN();
    VAR(rx_led_state)= ! VAR(rx_led_state);

#endif
}


static inline void flip_error_led()
{
#ifndef DISABLE_ASCENT_LEDS
    if (VAR(error_led_state)==0)
        CLR_YELLOW_LED_PIN();
    else
        SET_YELLOW_LED_PIN();
    VAR(error_led_state)= ! VAR(error_led_state);
#endif
}


static inline void turn_off_leds()
{
	SET_RED_LED_PIN();
	SET_GREEN_LED_PIN();
	SET_YELLOW_LED_PIN();
}


static inline void turn_on_leds()
{
#ifndef DISABLE_ASCENT_LEDS
	CLR_RED_LED_PIN();
	CLR_GREEN_LED_PIN();
	CLR_YELLOW_LED_PIN();
#endif
}


/* Events */
/* This is called when ASCENT receives a packet from the MAC layer */
/* TODO: Make this smaller ! */
TOS_MsgPtr TOS_EVENT(ASCENT_RX_PACKET)(TOS_MsgPtr data)
{

	if (data==NULL) {
		return data;
	}

	/* Drop all received packets until  "actual" bootup */
	/* Only handle the reset message */
	if ((VAR(state)==STATE_NULL) && ((uint8_t)data->type!=ASCENT_RESET)) {
		return NULL;
	}

	VAR(rx_addr)=(uint8_t)data->addr;
	VAR(rx_type)=(uint8_t)data->type;
#ifdef USE_ASCENT
	VAR(rx_seqnum)=(uint16_t)data->seq;
#endif // USE_ASCENT
	
#ifndef REAL_SLEEP
	if (VAR(state)==STATE_SLEEP) {
		switch ((uint8_t)data->type) {
			case ASCENT_CONFIG:
				if (data->addr==TOS_LOCAL_ADDRESS ||
					 data->addr==TOS_BCAST_ADDR) {
				  	struct config_msg *conf;
					conf=(struct config_msg *)(data->data);
					if (conf==NULL)
						break;
					if (conf->nt!=0) {
						VAR(nt)=conf->nt;
						udb_byte(conf->nt);                                                          }
					if (conf->lt!=0) {
						VAR(lt)=conf->lt;
						udb_byte(conf->lt);                                                          }
					if (conf->tt!=0) {
						VAR(tt)=conf->tt;
						udb_byte(conf->tt);
						VAR(timer_test)=(conf->tt)*timer1ps;                                        }
					if (conf->tp!=0) {
						VAR(tp)=conf->tp;
						udb_byte(conf->tp);
						VAR(timer_passive)=(conf->tp)*timer1ps;                                     }
					if (conf->ts!=0) {
						VAR(ts)=conf->ts;
						udb_byte(conf->ts);
						VAR(timer_sleep)=(conf->ts)*timer1ps;                                       }
					if (conf->pot!=0) {
						VAR(pot)=conf->pot;
						udb_byte(conf->pot);
						TOS_CALL_COMMAND(ASCENT_POT_SET)(conf->pot);
					}
				}
				break;
	        case ASCENT_RESET:
				if (data->addr==TOS_LOCAL_ADDRESS ||
					data->addr==TOS_BCAST_ADDR) {
					/* Set the watchdog to 47msec */
					wdt_enable(0x00);
				}
				break;                
			case ASCENT_DUMP:
				if (data->addr==TOS_LOCAL_ADDRESS ||
					data->addr==TOS_BCAST_ADDR) {
					VAR(uart_dump_caller)=EXPLICIT;
					TOS_POST_TASK(ASCENT_UART_DUMP);
					return data;
				}
				break;                         
			default:
				if (data->addr<MAX_NODES) {
					VAR(node)[data->addr].pkt_cnt++;
				}
				break;
		}
#ifdef USE_UART_AGGRESIVELY
		VAR(uart_dump_caller)=RX;
		TOS_POST_TASK(ASCENT_UART_DUMP);
#endif //U_U_A
		return NULL;
	}	
#endif //REAL_SLEEP
	
//	flip_error_led();	
	switch ((uint8_t)data->type) {
		case ASCENT_ANNOUNCEMENT:
			if (data->addr<MAX_NODES) {
				if (VAR(node)[data->addr].is_neighbor==0) {
					VAR(node)[data->addr].is_neighbor=1;
					VAR(node)[data->addr].recv_announcement=1;
					VAR(lastAnnouncementID)=data->addr;
					TOS_POST_TASK(ASCENT_COUNT_NEIGHBORS);
				}
			} 
			VAR(acount)++; 
			//flip_rx_led();
			TOS_POST_TASK(ASCENT_STATEMACHINE);
        	break;                  
		case ASCENT_HELP:
			if (data->addr<MAX_NODES) {
				if (VAR(node)[data->addr].is_neighbor==0) {
					VAR(node)[data->addr].is_neighbor=1;
					TOS_POST_TASK(ASCENT_COUNT_NEIGHBORS);
				}
			}
			VAR(help_received)=1;
			VAR(hcount)++;
			/* Try to avoid an avalanche effect of help messages 
			 * Otherwise, posting statemachine will check the data loss
			 * and since that hasn't changed (after all I received a
			 * help message) I will retransmit a help message. This will
			 * cause the originator of the other help message to transmit
			 * another one ==>> Avalanche effect.
			 * And after all, state cannot change after ACTIVE, so not
			 * posting another statemachine will not hurt
			*/
			if (VAR(state)!=STATE_ACTIVE) {
				TOS_POST_TASK(ASCENT_STATEMACHINE);
			}
			break;
		case ASCENT_CONFIG: 
			if (data->addr==TOS_LOCAL_ADDRESS ||
				data->addr==TOS_BCAST_ADDR) {
				struct config_msg *conf;
				conf=(struct config_msg *)(data->data);
				if (conf==NULL)
					break;
				if (conf->nt!=0) {
					VAR(nt)=conf->nt;
					udb_byte(conf->nt);
				}
				if (conf->lt!=0) {
					VAR(lt)=conf->lt;
					udb_byte(conf->lt);
				}
				if (conf->tt!=0) {
					VAR(tt)=conf->tt;
					udb_byte(conf->tt);
					VAR(timer_test)=(conf->tt)*timer1ps;
				}
				if (conf->tp!=0) {
					VAR(tp)=conf->tp;
					udb_byte(conf->tp);
					VAR(timer_passive)=(conf->tp)*timer1ps;
				}
				if (conf->ts!=0) {
					VAR(ts)=conf->ts;
					udb_byte(conf->ts);
					VAR(timer_sleep)=(conf->ts)*timer1ps;
				}
				if (conf->pot!=0) {
					VAR(pot)=conf->pot;
					udb_byte(conf->pot);
					TOS_CALL_COMMAND(ASCENT_POT_SET)(conf->pot);                                }       
			}	
			break;	
		case ASCENT_RESET:
			if (data->addr==TOS_LOCAL_ADDRESS ||
				data->addr==TOS_BCAST_ADDR) {
				/* Set the watchdog to 47msec, the lowest it can go */
				wdt_enable(0x00);
			}	
			break;
		case ASCENT_DUMP:
			if (data->addr==TOS_LOCAL_ADDRESS || 
				data->addr==TOS_BCAST_ADDR) {
				VAR(uart_dump_caller)=EXPLICIT;
				TOS_POST_TASK(ASCENT_UART_DUMP);
				return data;
			}
			break;
		default:
/* diffusion uses addr as a destination adderss-this breaks things */
#ifdef USE_DIFFUSION
			/* Not very elegant. It might eventually need to be implemented
			   in a switch statement */
			if ((uint8_t)data->type==DATA_TYPE) {
				VAR(diffMsg)=(DataMessage *)data->data;	
				VAR(dataaddr)=(uint8_t)(VAR(diffMsg)->sender);
				VAR(rx_addr)=VAR(dataaddr);
			} else if ((uint8_t)data->type==INTEREST_TYPE) {
				VAR(diffMsg)=(InterestMessage *)data->data;
				VAR(dataaddr)=(uint8_t)(VAR(diffMsg)->sender);
				VAR(rx_addr)=VAR(dataaddr);
			} else {
				/* Ignore all other packets */
				VAR(dataaddr)=0;
				VAR(rx_addr)=0;
			}
#else
			VAR(dataaddr)=(uint8_t)(data->addr);
#endif

#ifdef USE_ASCENT
			VAR(dataseq)=data->seq;
#endif
			if (VAR(dataaddr)<MAX_NODES && VAR(dataaddr)>0) {
				VAR(node)[VAR(dataaddr)].pkt_cnt++;
				TOS_POST_TASK(ASCENT_LLLR);
			}
#ifdef USE_DIFFUSION
			/* Check the type of the message */
			if ((uint8_t)data->type==DATA_TYPE) {
				VAR(diff_seqnum)=(uint16_t)(VAR(diffMsg)->orgSeqNum&0xFFFF);
				VAR(diff_sender)=(uint8_t)(VAR(diffMsg->x)+VAR(diffMsg->y));
				if (VAR(dataaddr)<MAX_NODES && VAR(dataaddr)>0)
					TOS_POST_TASK(ASCENT_DLLR);
			}
#endif

			TOS_SIGNAL_EVENT(ASCENT_RX_PACKET_READY)(data);
			break;
	}
#ifdef USE_UART_AGGRESIVELY
	VAR(uart_dump_caller)=RX;
	TOS_POST_TASK(ASCENT_UART_DUMP);
#endif // U_U_A
	return data;
}


/* Radio is available */
char TOS_EVENT(ASCENT_SUB_TX_PACKET_DONE)(TOS_MsgPtr data)
{
	VAR(data_to_radio_busy)=0;
/* The reason behind this is that since the application didn't transmit the
 * packet, I shouldn't signal it.
*/

	if (VAR(control_packet)==0) {
		TOS_SIGNAL_EVENT(ASCENT_TX_PACKET_DONE)(data);
	} else {
		VAR(control_packet)=0;
	}

#ifdef USE_UART_AGGRESIVELY
	VAR(uart_dump_caller)=TX;
	TOS_POST_TASK(ASCENT_UART_DUMP);
#endif // U_U_A
	return 1;
}


/* Uart */
char TOS_EVENT(ASCENT_UART_TX_PACKET_DONE)(TOS_MsgPtr data)
{
	VAR(uart_to_host_busy)=0;
	return 1;
}

TOS_MsgPtr TOS_EVENT(ASCENT_UART_RX_PACKET_DONE)(TOS_MsgPtr data)
{
	/* empty */
	return 0;
}


/* Commands */
/* This is called by upper components when they want to transmit a packet
 * ASCENT adds a sequence number to the provided TOS Msg pointer
 * and then sends the packet for transmission to the lower component
 * NOTICE: Needs modified MSG.h to work
*/
char TOS_COMMAND(ASCENT_TX_PACKET)(TOS_MsgPtr data)
{
	if (data==NULL || VAR(state)==STATE_PASSIVE 
		|| VAR(state)==STATE_SLEEP || VAR(state)==STATE_NULL) {
		return 0;
	}
	
	VAR(tx_type)=data->type;
#ifdef USE_ASCENT
	VAR(seq_sent)++;
	data->seq=VAR(seq_sent);
#endif

	if (VAR(data_to_radio_busy)==1) {
//		flip_error_led();
#ifdef USE_ASCENT
		VAR(seq_sent)--;
#endif
		return 0;	
	}
	if (TOS_COMMAND(ASCENT_SUB_TX_PACKET)(data)) {
		VAR(data_to_radio_busy)=1;
		flip_tx_led();
		return 1;
	}

	/* If this part of code is reached, paket sending failed. So the
	 * sequence number should be decremented 
	*/
#ifdef USE_ASCENT
	VAR(seq_sent)--;
#endif
	flip_error_led();
	return 0;
}


/* This command is used by the application when there is a need to send
 * HELP messages
*/
char TOS_COMMAND(ASCENT_XMIT_HELP)() 
{
	return (send_ascent_packet(ASCENT_HELP));
}	


/* Internal Functions */
/* Loss rate calculation functions */
static inline void link_level_loss_rate(uint8_t i, uint16_t current_seq)
{
	uint16_t offset=0;
	uint8_t sum=0;
	uint8_t j=0;
	uint32_t tmp;

	if (i==0 || i>=MAX_NODES)
		return;	

	/* Packet received, node isn't idle */
	VAR(node)[i].isnot_idle=1;

	/* If node has just booted OR if it just woke up, everything is
	 * reset to zero. In that case, first sequence number received is
	 * assigned to node[i].seq, and then the function returns. Two or more
	 * seqnums are needed to calculate loss rate	
	*/
	if (VAR(node)[i].window_size==0) {
		VAR(node)[i].seq=current_seq;
		VAR(node)[i].window_size=1;
		VAR(node)[i].vector|=0x1;
		goto lllr_done;
	}
	
	/* seqnum is a 16bit unsigned int, so it will take 65536 packets before 
	 * it rolls over. Since the rate is ~1 packet/sec, this will happen 
	 * ~18 hours from the beginning. It is MUCH more likely that something
	 * else will have gone wrong before that time, like a node rebooting,
	 * therefore resetting its seqnum to 0. This is the case that I handle
	*/
	if (VAR(node)[i].seq>current_seq) {
		VAR(node)[i].window_size=1;
		offset=1;
		if (VAR(node)[i].is_neighbor==1) {
			VAR(node)[i].is_neighbor=0;
//			VAR(neighbors)--;
		}
		VAR(node)[i].vector=0x0;
		VAR(node)[i].pkt_cnt=1;
		goto lllr_done;	
	} else {
		/* Offset is the difference between last received seqnum and current
		 * seqnum. If it is 1, there is no packet loss. Anything > 1 means 
		 * some packets were not received
		*/ 	
		offset=(int)(current_seq-VAR(node)[i].seq);
	}

	VAR(node)[i].seq=current_seq;

	/* Handle the initial case where the window is not full */
	if ((VAR(node)[i].window_size+offset) < VAR(vector_size)) {
		VAR(node)[i].window_size+=offset;
	} else {
		VAR(node)[i].window_size=VAR(vector_size);
	}

	/* Left shift the vector by the offset. Shift is always >=1 */
	VAR(node)[i].vector = VAR(node)[i].vector << offset;
	/* Add a 1 at the end, since the packet was received */	
	VAR(node)[i].vector |=0x1;								
	tmp=VAR(node)[i].vector;
	/* Count the number of 1s */
	for (j=0; j<VAR(node)[i].window_size; j++) {
		sum+=(tmp)&(0x1);	
		tmp=tmp>>1;
	}

	if (VAR(node)[i].window_size==0)
		goto lllr_done;
	VAR(node)[i].lossrate=100-(100*sum)/VAR(node)[i].window_size;

	/* 0 and 1 are special cases. I am using magic numbers */
	if (VAR(neighbors)==0) 
		VAR(nlt)=15;
	else if (VAR(neighbors)==1) 
		VAR(nlt)=30;
	else
		VAR(nlt)=(100-100/(VAR(neighbors)));

	if ((VAR(nlt)>=(VAR(node)[i].lossrate))) {
/*
		if (VAR(node)[i].is_neighbor==0) {
			VAR(neighbors)++;
*/
			VAR(node)[i].is_neighbor=1;
/*
		}
*/
	} else {
/*
		if ((VAR(nlt)<100) && (VAR(node)[i].is_neighbor==1)) {
			VAR(neighbors)--;
*/
			VAR(node)[i].is_neighbor=0;
/*
		}
*/
	}

lllr_done:
	TOS_POST_TASK(ASCENT_COUNT_NEIGHBORS);
//	TOS_POST_TASK(ASCENT_STATEMACHINE);	
	return;
}

/* Data level loss calculating function. Similar in many ways to the previous
 * one
*/
static inline void data_level_loss_rate(uint8_t i, uint16_t current_seq)
{

	uint16_t offset=0;
	uint8_t sum=0;
	uint8_t j=0;
	uint32_t tmp;
	
	if (VAR(path)[i].window_size==0) {
		VAR(path)[i].seq=current_seq;
		VAR(path)[i].window_size=1;
		VAR(path)[i].vector|=0x1;
		goto dllr_done;
	}
/*
	if (VAR(path)[i].seq>current_seq) {
		VAR(path)[i].window_size=1;
		offset=1;
		VAR(path)[i].vector=0x0;
		VAR(path)[i].pkt_cnt=1;
		goto dllr_done;
	} else {
*/
	offset=(int)(current_seq-VAR(path)[i].seq);
//	}

	if (offset<=0)
		/* same data received twice, return immediately */
		goto dllr_done;	

	VAR(path)[i].seq=current_seq;

	if ((VAR(path)[i].window_size+offset) < VAR(vector_size)) {
		VAR(path)[i].window_size+=offset;
	} else {
		VAR(path)[i].window_size=VAR(vector_size);
	}

	VAR(path)[i].vector=VAR(path)[i].vector << offset;
	VAR(path)[i].vector |=0x1;
	tmp=VAR(path)[i].vector;
	
	for (j=0; j<VAR(path)[i].window_size; j++) {
		sum+=(tmp)&(0x1);
		tmp=tmp>>1;
	}

	if (VAR(path)[i].window_size==0)
		goto dllr_done;
	VAR(path)[i].lossrate=100-(100*sum)/VAR(path)[i].window_size;
/*
	udb_byte(210);
	udb_byte(i);
	udb_byte(current_seq);
	udb_byte(sum);
	udb_byte(VAR(path)[i].window_size);
	udb_byte(VAR(path)[i].lossrate);
*/
	/* Variable reuse. is_neighbor is used as a flag for calculating
	 * the average loss rate, tmp is the sum of the valid lossrates
	 * and sum is the number of the valid lossrates
	*/
	tmp=0;
	sum=0;
	VAR(path)[i].is_neighbor=1;	
	for (j=0;j<MAX_PATHS;j++) {
		if (VAR(path)[j].is_neighbor==1) {
			tmp+=VAR(path)[j].lossrate;
			sum++;
		}
	}
	/* Average data loss */
/*
	udb_byte(sum);
	udb_byte(210);
*/

	if (sum>0)
		VAR(data_loss)=tmp/sum;	
/*
	else 
		VAR(data_loss)=199;
*/
	
	
dllr_done:
	TOS_POST_TASK(ASCENT_STATEMACHINE);
	return;
}


/* Function used to send control packets */
static inline char send_ascent_packet(uint8_t type)
{
	VAR(ascent_pkt).addr=TOS_LOCAL_ADDRESS;
	VAR(ascent_pkt).type=type;
	VAR(ascent_pkt).group=DEFAULT_LOCAL_GROUP;
#ifdef USE_ASCENT
	VAR(ascent_pkt).seq=VAR(seq_sent);
#endif
	VAR(tx_type)=type;	
	if (VAR(data_to_radio_busy)==1) 
		return 0;

	if (TOS_CALL_COMMAND(ASCENT_SUB_TX_PACKET)(&VAR(ascent_pkt))) {
		VAR(data_to_radio_busy)=1;
		VAR(control_packet)=1;
		flip_tx_led();
		return 1;
	}

//
//	flip_error_led();
	return 0;
}


static inline void clean_wakeup()
{
	uint8_t i=0;
	/* Clear the structs, but don't clear the packet count */
	for (i=0;i<MAX_PATHS;i++) {
		memset(&VAR(node)[i], 0, sizeof(struct loss)-sizeof(uint16_t));
		memset(&VAR(path)[i], 0, sizeof(struct loss));
	}
	for (i=MAX_PATHS;i<MAX_NODES;i++) {
		memset(&VAR(node)[i], 0, sizeof(struct loss)-sizeof(uint16_t));
	}
	/* Clear the variables */
	VAR(neighbors)=0;
	VAR(data_loss_T)=0;
	VAR(data_loss)=0;
	VAR(just_started)=1;
}


static inline uint8_t resolve_neighbor_clash()
{
	uint8_t i=0;
	uint8_t ncount=0;
	for (i=1; i<MAX_NODES; i++) {
		if (VAR(node)[i].is_neighbor==1)  {
			if (VAR(node)[i].recv_announcement==1) {
				if (i>TOS_LOCAL_ADDRESS) {
					VAR(node)[i].is_neighbor=0;
					continue;
				}	
			}
			ncount++;
		}	
	}
	if (ncount<=NT)	{
		/* Stay in test for the moment */
		TOS_POST_TASK(ASCENT_COUNT_NEIGHBORS);
		return 1;
	} else {
		/* Definately go passive */
		TOS_POST_TASK(ASCENT_COUNT_NEIGHBORS);
		return 0;
	}
}

/* Selects which timer to activate based on state */
static inline void activate_timer()
{
	VAR(random)=TOS_CALL_COMMAND(ASCENT_RAND)();
	switch (VAR(state)) {
		case STATE_NULL:
			VAR(random)=VAR(random)<<6;
			if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
				(&VAR(Tn), (VAR(random)+timer1ps)) == 0) {
			VAR(timer_sema)++;
			TOS_POST_TASK(ASCENT_NULL_TIMER_TASK);
			}
		break;
		case STATE_TEST:
			VAR(random)=VAR(random)<<11;
			if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
				(&VAR(Tt), VAR(timer_test)+VAR(random)) == 0) {
				VAR(timer_sema)++;
				TOS_POST_TASK(ASCENT_TEST_TIMER_TASK);
			}
		break;
		case STATE_PASSIVE:
			VAR(random)=VAR(random)<<12;
			if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
				(&VAR(Tp), VAR(timer_passive)+VAR(random)) == 0) { 
				VAR(timer_sema)++;
				TOS_POST_TASK(ASCENT_PASSIVE_TIMER_TASK);
			}
		break;
		case STATE_SLEEP:
			VAR(random)=VAR(random)<<14;
			if (TOS_CALL_COMMAND(ASCENT_ADD_TIMER)
				(&VAR(Ts), VAR(timer_sleep)+VAR(random)) == 0) {
				VAR(timer_sema)++;
				TOS_POST_TASK(ASCENT_SLEEP_TIMER_TASK);
			}
		break;
		default:
		break;                                                                  	}
}

/* timer deletion functions */
static inline void delete_test_timer()
{
	if (TOS_CALL_COMMAND(ASCENT_DEL_TIMER)(&VAR(Tt))==0) {
		VAR(timer_sema)++;
		TOS_POST_TASK(ASCENT_DEL_TEST_TIMER_TASK);
	}
}

static inline void delete_passive_timer()
{
	if (TOS_CALL_COMMAND(ASCENT_DEL_TIMER)(&VAR(Tp))==0) {
		VAR(timer_sema)++;
		TOS_POST_TASK(ASCENT_DEL_PASSIVE_TIMER_TASK);
	}
}


/* Creates a dump message */
static inline void create_dump_msg(struct dump_msg *msg)
{
	msg->frame0=111;
	msg->pot=(uint8_t)TOS_CALL_COMMAND(ASCENT_POT_GET)();
	msg->caller=VAR(uart_dump_caller);
	msg->nt=VAR(nt);
	msg->lt=VAR(lt);
	msg->tt=VAR(tt);
	msg->tp=VAR(tp);
	msg->ts=VAR(ts);
	msg->state=VAR(state);
	msg->tcount=VAR(tcount);
	msg->pcount=VAR(pcount);
	msg->scount=VAR(scount);
	msg->hcount=VAR(hcount);
	msg->acount=VAR(acount);
	msg->nlt=VAR(nlt);
	msg->data_loss=VAR(data_loss);
	msg->neighbors=VAR(neighbors);
	msg->nbts=VAR(data_loss_T);

	msg->rx_addr=VAR(rx_addr);
	msg->rx_type=VAR(rx_type);
	msg->rx_seqnum_H=((VAR(rx_seqnum)>>8) & 0xFF);
	msg->rx_seqnum_L=(VAR(rx_seqnum) & 0xFF);
	msg->tx_type=VAR(tx_type);
	msg->tx_seqnum_H=((VAR(seq_sent)>>8) & 0xFF); 
	msg->tx_seqnum_L=(VAR(seq_sent) & 0xFF);
/*
	msg->node1_loss=VAR(node)[2].lossrate;
	msg->node1_windowsize=VAR(node)[2].window_size;
	msg->node1_pktcnt=(uint8_t)VAR(node)[2].pkt_cnt;
	msg->node2_loss=VAR(node)[3].lossrate;
	msg->node2_windowsize=VAR(node)[3].window_size;
	msg->node2_pktcnt=(uint8_t)VAR(node)[3].pkt_cnt;
	msg->node3_loss=VAR(node)[4].lossrate;
	msg->node3_windowsize=VAR(node)[4].window_size;
	msg->node3_pktcnt=(uint8_t)VAR(node)[4].pkt_cnt;
*/
	msg->frame1=222;
} // 28 bytes


/* Serial debug functions */
#ifdef SP_DBG
void udb_byte(unsigned char data)
{
	do {
		while( (inp(UART_SR) & 0x20) == 0)
			{};
		outp(data, UDR);
	}
	while(0);
}


void udb_init(unsigned char bandwidth)
{
	outp(bandwidth,UBRR);
	inp(UDR);
	outp(0x08,UART_CR);
}              
#endif                                        

                                            	
