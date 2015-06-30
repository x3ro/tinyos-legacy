
#include "RadioCountToLeds.h"

module RadioCountToLedsP {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli>;
    interface SplitControl;
    interface Packet;
    interface PacketAcknowledgements;
  }
}
implementation {

  message_t packet;
  
  uint16_t counter;
  
  bool radioOn;
  
  /***************** Prototypes ****************/
  task void send();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    radioOn = FALSE;
    counter = 0;
    call PacketAcknowledgements.requestAck(&packet);
    call SplitControl.start();
  }

  /***************** SplitControl Events ****************/
  event void SplitControl.startDone(error_t err) {
    radioOn = TRUE;
    call Timer.startOneShot(512);
    call Leds.led0On();
    call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t));
  }

  event void SplitControl.stopDone(error_t err) {
    call Leds.set(0);
    call Timer.startOneShot(512);
    radioOn = FALSE;
  }
  
  /***************** Timer Events ****************/
  event void Timer.fired() {
    if(radioOn) {
      call SplitControl.stop();
    } else {
      call SplitControl.start();
    }
  }

  /***************** Receive Events ****************/
  event message_t* Receive.receive(message_t* bufPtr, 
                                   void* payload, uint8_t len) {
    call Leds.led1Toggle();
    return bufPtr;
  }
  
  /***************** AMSend Events ***************/
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    radio_count_msg_t* rcm = (radio_count_msg_t*) call Packet.getPayload(&packet, sizeof(radio_count_msg_t)); 
    
    call Leds.led2Toggle();
    if(!radioOn) {
      call Leds.set(0);
    }
    
    counter++;
    rcm->counter = counter;

    post send();
  }

  /***************** Tasks ****************/
  task void send() {
    if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) != SUCCESS) {
      post send();
    }
  }

}
