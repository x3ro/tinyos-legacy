includes EventLoggerPerl;

module TestLoggerM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Leds;
    interface EventLogger;
    interface Random;
    interface MgmtAttr as MA_Seqno;
    interface MgmtAttr as MA_SeqnoSlow;
  }
}
implementation {

  uint16_t seqno;
  uint32_t seqno_slow;

  command result_t StdControl.init() {
    call MA_Seqno.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_SeqnoSlow.init(sizeof(uint32_t), MA_TYPE_UINT);
    call Random.init();
    seqno_slow = 0;
    seqno = seqno_slow;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call Timer.start(TIMER_ONE_SHOT, call Random.rand() % 1024);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    
    result_t result;

    call Leds.greenToggle();

    seqno++;
    if (seqno % 2 == 0) {
      seqno_slow++;
      <snms>
	 result = logEvent("Seqno: %2d, Seqno_Slow: %4d", seqno, seqno_slow); 
      </snms>
	  } else {
      <snms> 
	 logEvent("Seqno_Slow: 0x%4x, Seqno: %2d", seqno_slow, seqno); 
      </snms>
	  }


    call Timer.start(TIMER_ONE_SHOT, 1024);
    return SUCCESS;
  }
  
  event result_t MA_Seqno.getAttr(uint8_t *resultBuf) {
    memcpy(resultBuf, &seqno, sizeof(seqno));
    return SUCCESS;
  }
  event result_t MA_SeqnoSlow.getAttr(uint8_t *resultBuf) {
    memcpy(resultBuf, &seqno_slow, sizeof(seqno_slow));
    return SUCCESS;
  }
}
