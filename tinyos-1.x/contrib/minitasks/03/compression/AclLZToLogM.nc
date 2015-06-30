/*									tab:4
 * Authors:   Ning Xu
 * History:   create 10/26/2002
 *            Modify 05/02/2003:for continuous sampling
 *            Modify 05/15/2003:for timer-driven sampling
 *            
 * This component sampling the accelerometer at 128Hz,compress the sampling using LZ77 algorithm and write the result to
 * the logger at 32 lines per second.
 */

module AclLZToLogM
{
  provides interface StdControl;
  provides interface Sensing;
  uses {
    interface Leds;
    interface Clock;
    interface ADC as AccelX;
    interface ADC as AccelY;
    interface StdControl as SubControl;
    interface LoggerWrite;
    interface ProcessCmd as CmdExecute;
  }
}
implementation
{
  enum {
        SAMPLE_NUM = 800,
        MAX_MATCH_LENGTH = 16,
        SLIDING_WINDOW_SIZE = 50,
        DELAY = 4,
  };
  uint8_t buflog[32], *bufptr[2]; //alternate buffer for logger writing
  uint8_t empty[16], i, *pempty;
  uint8_t head, currLogBuf, accelBuffer, lzBuffer;	
  uint16_t log_delay, currPos, p, ptrSlidingWindow, ptrLookAhead;
  uint16_t buffer[2][SAMPLE_NUM]; //we use double buffers to store sample data 
  bool    LogClear, accelOn, BufferClear;

  command result_t StdControl.init() {
    currPos = 0;
    LogClear = TRUE;
    accelOn = FALSE;
    BufferClear = TRUE;

    ptrSlidingWindow = 0;
    ptrLookAhead = 0;
    p = 0;
    head = 0;
    currLogBuf = 0;
    log_delay = 0;

    bufptr[0] = &(buflog[0]);
    bufptr[1] = &(buflog[16]);
    pempty = &(empty[0]);

    for ( i=0; i<16; i++ ) empty[i] = 0;

    return rcombine(call SubControl.init(),
		    call Leds.init());
  }

  command result_t StdControl.start() {
      call SubControl.start();
      return call Clock.setRate(TOS_I128PS, TOS_S128PS);
  }

  command result_t StdControl.stop() {
      call Clock.setRate(TOS_I0PS, TOS_S0PS);
      return call SubControl.stop();
  }

  command result_t Sensing.start(int8_t seqno) {
      accelOn = TRUE;
      return SUCCESS;
  }
  command result_t Sensing.stop(int8_t seqno) {
      accelOn = FALSE;
      return SUCCESS;
  }

  event result_t Clock.fire() {
    if (accelOn) call AccelX.getData(); /* start data reading */
    if (!LogClear) {
                   log_delay--;
                   if (log_delay == 0) LogClear = TRUE; //max logger writing speed is 32 line per second
    }
    return SUCCESS;
  }

  event result_t AccelY.dataReady(uint16_t data) {
    return SUCCESS;
  }
  event result_t LoggerWrite.writeDone (result_t status) {
        return SUCCESS;
  }
  event result_t CmdExecute.done(TOS_MsgPtr pmsg,result_t status) {
        return SUCCESS;
  }

  task void lz77() {
    if ( LogClear && (ptrLookAhead < SAMPLE_NUM)) {
               if (ptrLookAhead > SLIDING_WINDOW_SIZE)  ptrSlidingWindow = ptrLookAhead - SLIDING_WINDOW_SIZE;
                                             else       ptrSlidingWindow = 0;
               if (ptrLookAhead < 2) {
                                       bufptr[currLogBuf][head] = ((buffer[lzBuffer][ptrLookAhead]) >> 8) & 0x7f ;  //direct sample, MSB=0
                                       bufptr[currLogBuf][head+1] = buffer[lzBuffer][ptrLookAhead] & 0xff ;
                                       ptrLookAhead++ ;
                                       head += 2 ;
               }   else   {
                                       int ptr = 0 ;
                                       uint8_t len_max = 0, pi ;
                                       p = ptrSlidingWindow ;
                                       do {
                                                 //Search for the longest match in the sliding window
                                                 pi = 0;
                                                 while ((buffer[lzBuffer][p+pi] == buffer[lzBuffer][ptrLookAhead+pi])&&\
                                                       ((ptrLookAhead+pi) < SAMPLE_NUM)&& \
                                                       ((p+pi) < ptrLookAhead) && ( pi < MAX_MATCH_LENGTH))
                                                       pi++;
                                                 if (pi > len_max) {
                                                                  ptr = p;
                                                                  len_max = pi; 
                                                 }
                                                 if ( len_max == MAX_MATCH_LENGTH ) p = ptrLookAhead; //no need for further search
                                                 p++;
                                       }
                                       while ( p <= (ptrLookAhead-2)) ;
                                       if (len_max > 1) {
                                                        //set the MSB to 1, indicating it is a codeword      
                                                        bufptr[currLogBuf][head] = len_max | 0x80 ;
                                                        bufptr[currLogBuf][head+1] = ptrLookAhead - ptr ;      
                                                        ptrLookAhead += len_max ;
                                       } else {
                                                        bufptr[currLogBuf][head] = (buffer[lzBuffer][ptrLookAhead]>>8) ;
                                                        bufptr[currLogBuf][head+1] = buffer[lzBuffer][ptrLookAhead] & 0xff ;
                                                        ptrLookAhead++ ;
                                       }
                                       head += 2 ;
                                       if(ptrLookAhead == SAMPLE_NUM) {
                                          BufferClear = TRUE ;
                                          while ( head < 16 ) bufptr[currLogBuf][head++]= 0x44; //fill the rest of the line with 0x44
                                       }
                                       //write to Log
                                       if ( head == 16 ) {
                                                       head = 0;
                                                       call LoggerWrite.append((char *)bufptr[currLogBuf]);
                                                       log_delay = DELAY; //next task should be scheduled 1/32 second later
                                                       LogClear = FALSE;
                                                       currLogBuf ^= 0x01; //switch logger buffer
                                                       call Leds.yellowToggle();
                                       }
                }
   }
   post lz77(); //process next chunk of data
}

event result_t AccelX.dataReady(uint16_t data) {
    if ( currPos < SAMPLE_NUM ) {
        buffer[accelBuffer][currPos++] = data;
    } else {
        currPos = 0;
        if ( BufferClear ) {
                             lzBuffer = accelBuffer;
                             accelBuffer ^= 0x01; //switch sampling buffer
                             ptrSlidingWindow = 0;
                             ptrLookAhead = 0;
                             post lz77();
                             call LoggerWrite.append((char *)pempty); //mark the begining of the data segment 
                             log_delay = DELAY;
                             LogClear = FALSE;
                             BufferClear = FALSE;
        } else {
                             call Leds.redOn(); //error occurs, sampling outruns compressing, try lower sampling frequency
        }
    }
    return SUCCESS;
}
}
