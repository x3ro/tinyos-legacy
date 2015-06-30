// @author John Breneman <johnyb_4@berkeley.edu>
 
includes PWMMessage;
 
module PWMRadioReceiveM
{
  provides interface StdControl;
  uses interface ReceiveMsg;
  uses interface Timer;
  uses interface TelosPWM;
  uses interface Leds;
}
 
implementation
{
  TOS_Msg m_msg;
 
  command result_t StdControl.init()
  {
    call Leds.init();
    return SUCCESS;
  }
 
  command result_t StdControl.start()
  {
    call TelosPWM.setFreq( 17476 ); // 60 Hz
    call TelosPWM.setHigh0( 1536 );
    call TelosPWM.setHigh1( 1536 );
    call TelosPWM.setHigh2( 1536 );
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }
 
  command result_t StdControl.stop()
  {
    return SUCCESS;
  }
 
  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    PWMMsg_t* body = (PWMMsg_t*)msg->data;
    
    int steer1, steer2, throttle1, throttle2;
    steer1 = body->steer1;
    steer2 = body->steer2;
    throttle1 = body->throttle1;
    throttle2 = body->throttle2;

    if (steer1 > 127)
      call Leds.greenOn();
    else call Leds.greenOff();

    if (steer2 > 127)
      call Leds.redOn();
    else call Leds.redOff();

    if (throttle1 > 127)
      call Leds.yellowOn();
    else call Leds.yellowOff();

    if (steer1 > 255)
      steer1 = 255;
    else if (steer1 < 0)
      steer1 = 0;

   if (steer2 > 255)
      steer2 = 255;
    else if (steer2 < 0)
      steer2 = 0;

   if (throttle1 > 255)
      throttle1 = 255;
    else if (throttle1 < 0)
      throttle1 = 0;

   if (throttle2 > 255)
      throttle2 = 255;
    else if (throttle2 < 0)
      throttle2 = 0;

   call TelosPWM.setHigh0( 2*throttle1+1537 );
   call TelosPWM.setHigh1( 2*steer1+1537 );
   call TelosPWM.setHigh2( 2*steer2+1537 );
   
   return msg;
  }
  
  event result_t Timer.fired()
    {
      //      call Leds.yellowToggle();
      return SUCCESS;
    }
  
}
