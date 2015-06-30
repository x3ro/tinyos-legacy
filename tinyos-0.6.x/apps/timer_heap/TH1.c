
#include "tos.h"
#include "TH1.h"

//Frame Declaration
#define TOS_FRAME_TYPE TH1_frame
TOS_FRAME_BEGIN(TH1_frame) {
	uint8_t send_pending;
	Timer t1,t2,t3,t4;
	uint8_t r,g,y;
	TOS_Msg data;
}
TOS_FRAME_END(TH1_frame);

TOS_TASK(th1_insert_t1) {
  if (isFree(&VAR(t1)) && !TOS_CALL_COMMAND(TH1_TIMER)(&VAR(t1),2*timer1ps))
    TOS_POST_TASK(th1_insert_t1); 
}

TOS_TASK(th1_delete_t1) {
  if (!isFree(&VAR(t1)) && !TOS_CALL_COMMAND(TH1_SUB_TIMER_DELETE)(&VAR(t1)))
    TOS_POST_TASK(th1_delete_t1); 
}

TOS_TASK(th1_insert_t2) {
  if (isFree(&VAR(t2)) && !TOS_CALL_COMMAND(TH1_TIMER)(&VAR(t2),2*timer1ps))
    TOS_POST_TASK(th1_insert_t2); 
}

TOS_TASK(th1_delete_t2) {
  if (!isFree(&VAR(t2)) && !TOS_CALL_COMMAND(TH1_SUB_TIMER_DELETE)(&VAR(t2)))
    TOS_POST_TASK(th1_delete_t2); 
}

TOS_TASK(th1_insert_t3) {
  if (isFree(&VAR(t3)) && !TOS_CALL_COMMAND(TH1_TIMER)(&VAR(t3),10*timer1ps))
    TOS_POST_TASK(th1_insert_t3);
}

TOS_TASK(th1_delete_t3) {
  if (!isFree(&VAR(t3)) && !TOS_CALL_COMMAND(TH1_SUB_TIMER_DELETE)(&VAR(t3)))
    TOS_POST_TASK(th1_delete_t3); 
}

TOS_TASK(th1_insert_t4) {
  if (isFree(&VAR(t4)) && !TOS_CALL_COMMAND(TH1_TIMER)(&VAR(t4),45*timer1ps))
    TOS_POST_TASK(th1_insert_t4);
}

/* Toggle the Red LED on each tick. */
void th1_blink(){
  flip_red();
}

/* send packet on each tick */
void th1_send_packet() {
  flip_yellow();
  if (!VAR(send_pending)) {
    if (TOS_CALL_COMMAND(TH1_SUB_SEND_MSG)(TOS_BCAST_ADDR,7,&VAR(data))) VAR(send_pending) = 1;
  }
}

void th1_one_shot() {
  if (isFree(&VAR(t2)))
    TOS_POST_TASK(th1_insert_t2);
  else
    TOS_POST_TASK(th1_delete_t2);

  TOS_POST_TASK(th1_insert_t3);
}

/* terminate all timers 1 through 3 */
void th1_terminate() {
  if (!isFree(&VAR(t1))) TOS_POST_TASK(th1_delete_t1);
  if (!isFree(&VAR(t2))) TOS_POST_TASK(th1_delete_t2);
  if (!isFree(&VAR(t3))) TOS_POST_TASK(th1_delete_t3);
  SET_YELLOW_LED_PIN();
  SET_RED_LED_PIN();
}

/* TH1_INIT: 
   Clear all the LEDs
*/

char TOS_COMMAND(TH1_INIT)(){
  
  initTimer(&VAR(t1));
  /* Set to the callback function pointer */
  VAR(t1).f = th1_blink;
  /* set periodicity to 1 second*/
  setPeriodic(&VAR(t1),timer1ps);

  initTimer(&VAR(t2));
  /* Set to the callback function pointer */
  VAR(t2).f = th1_send_packet;
  /* set periodicity 2 seconds*/
  setPeriodic(&VAR(t2),timer1ps);

  initTimer(&VAR(t3));
  /* Set to the callback function pointer */
  VAR(t3).f = th1_one_shot;
  /* Set aperiodic timer */
  setAperiodic(&VAR(t3));

  initTimer(&VAR(t4));
  /* Set to the callback function pointer */
  VAR(t4).f = th1_terminate;
  /* Set aperiodic timer */
  setAperiodic(&VAR(t4));

  setDbg(&VAR(t1),1);
  setDbg(&VAR(t2),2);
  setDbg(&VAR(t3),3);
  setDbg(&VAR(t4),4);

  TOS_CALL_COMMAND(TH1_SUB_TIMER_INIT)();
  TOS_CALL_COMMAND(TH1_SUB_COMM_INIT)();
  return 1;
}

/* TH1_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(TH1_START)() {
  TOS_POST_TASK(th1_insert_t1);
  TOS_POST_TASK(th1_insert_t2);
  TOS_POST_TASK(th1_insert_t3);
  TOS_POST_TASK(th1_insert_t4);

  return 1;
}

/*   TH1_SUB_MSG_SEND_DONE event handler */
char TOS_EVENT(TH1_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
	//check to see if the message that finished was yours.
	//if so, then clear the send_pending flag.
  if(&VAR(data) == msg){ 
	  VAR(send_pending) = 0;
	  flip_yellow();
  }

  return 1;
}

void flip_yellow() {
  if (++VAR(y)%2) CLR_YELLOW_LED_PIN();
  else SET_YELLOW_LED_PIN();
}

void flip_red() {
  if (++VAR(r)%2) CLR_RED_LED_PIN();
  else SET_RED_LED_PIN();
}
