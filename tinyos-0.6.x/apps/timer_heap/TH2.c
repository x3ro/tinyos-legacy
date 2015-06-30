
#include "tos.h"
#include "TH2.h"

//Frame Declaration
#define TOS_FRAME_TYPE TH2_frame
TOS_FRAME_BEGIN(TH2_frame) {
	Timer t1,t2,t3,t4;
	uint8_t g;
	uint8_t send_pending;
	TOS_Msg data;
}
TOS_FRAME_END(TH2_frame);

TOS_TASK(th2_delete_t1) {
  if (!isFree(&VAR(t1)) && !TOS_CALL_COMMAND(TH2_SUB_TIMER_DELETE)(&VAR(t1)))
    TOS_POST_TASK(th2_delete_t1); 
}

TOS_TASK(th2_insert_t1) {
  if (isFree(&VAR(t1)) && !TOS_CALL_COMMAND(TH2_TIMER)(&VAR(t1),timer4ps))
    TOS_POST_TASK(th2_insert_t1);
}

TOS_TASK(th2_insert_t2) {
  if (isFree(&VAR(t2)) && !TOS_CALL_COMMAND(TH2_TIMER)(&VAR(t2),10*timer1ps))
    TOS_POST_TASK(th2_insert_t2);
}

TOS_TASK(th2_delete_t2) {
  if (!isFree(&VAR(t2)) && !TOS_CALL_COMMAND(TH2_SUB_TIMER_DELETE)(&VAR(t2)))
    TOS_POST_TASK(th2_delete_t2); 
}

TOS_TASK(th2_insert_t3) {
  if (isFree(&VAR(t3)) && !TOS_CALL_COMMAND(TH2_TIMER)(&VAR(t3),90*timer1ps))
    TOS_POST_TASK(th2_insert_t3);
}

TOS_TASK(th2_insert_t4) {
  if (isFree(&VAR(t4)) && !TOS_CALL_COMMAND(TH2_TIMER)(&VAR(t4),timer4ps))
    TOS_POST_TASK(th2_insert_t4);
}

TOS_TASK(th2_delete_t4) {
  if (!isFree(&VAR(t4)) && !TOS_CALL_COMMAND(TH2_SUB_TIMER_DELETE)(&VAR(t4)))
    TOS_POST_TASK(th2_delete_t4); 
}

/* Clock Event Handler:
   Toggle the Red LED on each tick.
 */
void th2_blink(){
  //  flip_green();
}

void th2_one_shot() {
  if (isFree(&VAR(t1)))
    TOS_POST_TASK(th2_insert_t1);
  else
    TOS_POST_TASK(th2_delete_t1);
  
  TOS_POST_TASK(th2_insert_t2);
}

/* terminate all above timers */
void th2_terminate() {
  if (!isFree(&VAR(t1))) TOS_POST_TASK(th2_delete_t1);
  if (!isFree(&VAR(t2))) TOS_POST_TASK(th2_delete_t2);  
  SET_GREEN_LED_PIN();
}

/* send packet on each tick */
void th2_send_packet() {
  if (!VAR(send_pending)) {
    if (TOS_CALL_COMMAND(TH2_SUB_SEND_MSG)(TOS_BCAST_ADDR,7,&VAR(data))) {
      flip_green();
      VAR(send_pending) = 1;
    }
  }
}

/* TH2_INIT: 
   Clear all the LEDs and initialize state
*/
char TOS_COMMAND(TH2_INIT)(){

  initTimer(&VAR(t1));
  /* Set to the callback function pointer */
  VAR(t1).f = th2_blink;
  /* Set aperiodic timer */
  setPeriodic(&VAR(t1),timer4ps);

  initTimer(&VAR(t2));
  /* Set to the callback function pointer */
  VAR(t2).f = th2_one_shot;
  /* Set aperiodic timer */
  setAperiodic(&VAR(t2));
  //  setPeriodic(&VAR(t2),10*timer1ps);

  initTimer(&VAR(t3));
  /* Set to the callback function pointer */
  VAR(t3).f = th2_terminate;
  /* Set aperiodic timer */
  setAperiodic(&VAR(t3));

  initTimer(&VAR(t4));
  /* Set to the callback function pointer */
  VAR(t4).f = th2_send_packet;
  /* Set aperiodic timer */
  setPeriodic(&VAR(t4),timer4ps);

  setDbg(&VAR(t1),5);
  setDbg(&VAR(t2),6);
  setDbg(&VAR(t3),7);

  TOS_CALL_COMMAND(TH2_SUB_TIMER_INIT)();
  TOS_CALL_COMMAND(TH2_SUB_COMM_INIT)();
  return 1;
}

/* TH2_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(TH2_START)() {
  TOS_POST_TASK(th2_insert_t1);
  TOS_POST_TASK(th2_insert_t2);
  TOS_POST_TASK(th2_insert_t3);
  TOS_POST_TASK(th2_insert_t4);

  return 1;
}

/*   TH2_SUB_MSG_SEND_DONE event handler */
char TOS_EVENT(TH2_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
	//check to see if the message that finished was yours.
	//if so, then clear the send_pending flag.
  if(&VAR(data) == msg){ 
	  VAR(send_pending) = 0;
	  flip_green();
  }

  return 1;
}


void flip_green() {
  if (++VAR(g)%2) CLR_GREEN_LED_PIN();
  else SET_GREEN_LED_PIN();
}

