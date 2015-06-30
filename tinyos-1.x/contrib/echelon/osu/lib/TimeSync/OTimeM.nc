includes OTime;

module OTimeM
{
  provides interface StdControl;
  provides interface OTime;
  uses {
    interface SysTime;
    interface Alarm;
    interface Leds;
  }
}
implementation
{
  timeSync_t LastClock;
  timeSync_t LastVClock;
  timeSync_t Displacement;

  /**
   * Time initialization. 
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.init() {
    
    return SUCCESS;
    }

  /**
   * Time startup.  
   * @author herman@cs.uiowa.edu
   */
  command result_t StdControl.start() {
    LastClock.ClockH = LastClock.ClockL = 0;   
    LastVClock.ClockH = LastVClock.ClockL = 0;  
    Displacement.ClockL = 0;
    Displacement.ClockH = 1;  // Hack for demo:  permits negative adjust 
    call Alarm.set(0,200);    // 200 seconds due to ??-second rollover
    return SUCCESS;
    }

  /**
   * Tsync stop.  Stops communication and alarm components.
   * @author herman@cs.uiowa.edu
   */
  command result_t StdControl.stop() {
    return SUCCESS;
    }

  /**
   * OTime.getLocalTime merely returns current local clock,
   * provided by SysTime.get().
   * @author herman@cs.uiowa.edu
   */
  command void OTime.getLocalTime( timeSyncPtr p ) { 

    p->ClockL = call SysTime.getTime32();

    // add to high-order part if carry implied by clock wrapping around

    if ( p->ClockL < LastClock.ClockL ) LastClock.ClockH++;

    LastClock.ClockL = p->ClockL;
    p->ClockH = LastClock.ClockH;

    }

  /**
   * OTime.getLocalTime32 returns the scaled-to-32-bits
   * version of getLocalTime
   * @author herman@cs.uiowa.edu
   */
  command uint32_t OTime.getLocalTime32( ) { 
    uint32_t r;
    uint32_t s;
    timeSync_t t;

    call OTime.getLocalTime(&t);
    // isolate "middle" 32 bits
    r = t.ClockL >> 14;  // discard low-order 14 bits.
    s = t.ClockH;        // s = hi order 16 bits from 48-bit clock
    s = s << 18;         // position 14 of these bits to be hi-order
    r = r | s;           // get hi-order (32-14)=18 bits
    return r;
    }

  /**
   * OTime.getGlobalTime adds current displacement 
   * to the localTime. 
   * @author herman@cs.uiowa.edu
   */
  command void OTime.getGlobalTime( timeSyncPtr p ) { 
    call OTime.getLocalTime(p);
    call OTime.add(p,&Displacement,p);
    // skewAdjust(p);
    LastVClock.ClockH = p->ClockH;
    LastVClock.ClockL = p->ClockL;
    }

  /**
   * OTime.getGlobalTime32 returns the scaled-to-32-bits
   * version of getGlobalTime
   * @author herman@cs.uiowa.edu
   */
  command uint32_t OTime.getGlobalTime32( ) { 
    uint32_t r;
    uint32_t s;
    timeSync_t t;

    call OTime.getGlobalTime(&t);
    // isolate "middle" 32 bits
    r = t.ClockL >> 14;  // discard low-order 14 bits.
    s = t.ClockH;        // s = hi order 16 bits from 48-bit clock
    s = s << 18;         // position 14 of these bits to be hi-order
    r = r | s;           // get hi-order (32-14)=18 bits
    return r;
    }

  /**
   * OTime.convLocalTime adds current displacement 
   * to the provided localTime to get Global Time. 
   * @author herman@cs.uiowa.edu
   */
  command void OTime.convLocalTime( timeSyncPtr p ) { 
    call OTime.add(p,&Displacement,p);
    // skewAdjust(p);
    LastVClock.ClockH = p->ClockH;
    LastVClock.ClockL = p->ClockL;
    }

  /**
   * OTime.adjGlobalTime adjusts current displacement. 
   * @author herman@cs.uiowa.edu
   */
  command void OTime.adjGlobalTime( timeSyncPtr p ) { 
    call OTime.add(p,&Displacement,&Displacement);
    }

  /**
   * OTime.lesseq compares two time values (a,b)
   * returning TRUE iff  a <= b
   */
  command bool OTime.lesseq( timeSyncPtr a, timeSyncPtr b ) {
    if (a->ClockH > b->ClockH) return FALSE;
    if (a->ClockH < b->ClockH) return TRUE;
    if (a->ClockL > b->ClockL) return FALSE;
    return TRUE;
    }

  /**
   * OTime.add sums two time values (a,b) into c
   */
  command void OTime.add( timeSyncPtr a, timeSyncPtr b, timeSyncPtr c ) {
    timeSync_t v;   // in case pointer c=b or c=a
    v.ClockH = a->ClockH + b->ClockH;
    v.ClockL = a->ClockL + b->ClockL;
    if (v.ClockL < a->ClockL || v.ClockL < b->ClockL) v.ClockH++;
    c->ClockH = v.ClockH;  c->ClockL = v.ClockL;
    }

  /**
   * OTime.subtract does c = a - b  (works only if a > b)
   */
  command void OTime.subtract( timeSyncPtr a, timeSyncPtr b, timeSyncPtr c ) {
    timeSync_t v;   // in case pointer c=b or c=a
    v.ClockH = a->ClockH - b->ClockH;
    v.ClockL = a->ClockL - b->ClockL;
    if (a->ClockL < b->ClockL) v.ClockH--;
    c->ClockH = v.ClockH;  c->ClockL = v.ClockL;
    }

  /**
   * Periodic firing of Alarm so we get a recent base
   * on the current value of SysTime
   * @author herman@cs.uiowa.edu
   */
  event result_t Alarm.wakeup(uint8_t indx, uint32_t wake_time) {
    timeSync_t m;
    call OTime.getGlobalTime( &m ); 
    call Alarm.set(0,200);   // reschedule self  
    return SUCCESS;
    }

}
