/*
*/

#include "Ditto.h"

module DittoP {
  provides interface StdControl;

  uses interface Spram;

  uses interface Microphone;

#ifndef PLAYRECORD_NO_SPEAKER
  uses interface Speaker;
  uses interface PowerControl as SpeakerPowerControl;
  uses interface PowerKeepAlive as SpeakerPowerKeepAlive;
#endif

  uses interface ButtonAdvanced as Button;
  uses interface Leds;
  uses interface Timer2<TMilli> as LedsTimer;

  uses interface Random;
  uses interface LocalTime<T32khz> as LocalTime32khz;
}
implementation {

  enum {
    MIC_SAMPLES = 16,
    SCALED_AMPLITUDE = 16,
  };

  enum {
    STATE_AUDIO_IDLE = 0,
    STATE_AUDIO_SPEAKER_START,
    STATE_AUDIO_SPEAKER_START_2,
    STATE_AUDIO_SPEAKER_START_3,
    STATE_AUDIO_SPEAKER_START_4,
    STATE_AUDIO_COUNTDOWN_START,
    STATE_AUDIO_COUNTDOWN_1,
    STATE_AUDIO_COUNTDOWN_2,
    STATE_AUDIO_COUNTDOWN_3,
    STATE_AUDIO_COUNTDOWN_4,
    STATE_AUDIO_COUNTDOWN_5,
    STATE_AUDIO_COUNTDOWN_6,
    STATE_AUDIO_COUNTDOWN_7,
    STATE_AUDIO_RECORD_START,
    STATE_AUDIO_RECORD_RECORDING,
    STATE_AUDIO_RECORD_STOP,
    STATE_AUDIO_SCALE,
    STATE_AUDIO_PLAY_PLAYING,
  };

  uint16_t m_mic1[MIC_SAMPLES];
  uint16_t m_mic2[MIC_SAMPLES];
  uint16_t* m_micnext;
  uint8_t* m_micdest;
  uint8_t m_audio_state;
  bool m_speakerKeepAlive;

  uint8_t* samples() {
    return (uint8_t*)call Spram.getData();
  }

  // StdControl

  command result_t StdControl.init() {
    m_audio_state = STATE_AUDIO_IDLE;
    m_speakerKeepAlive = FALSE;
    call Random.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Button.enable();
    //call Spram.publish( NUM_SAMPLES );
    return SUCCESS;
  }


  command result_t StdControl.stop() {
    return SUCCESS;
  }


  // Record

  task void recordRecordTask();

  void recordCountdown() {
    switch( m_audio_state ) {
      case STATE_AUDIO_COUNTDOWN_1:
      case STATE_AUDIO_COUNTDOWN_3:
      case STATE_AUDIO_COUNTDOWN_5:
        call Leds.redOn();
        call LedsTimer.startOneShot( 200 );
        m_audio_state++;
        break;

      case STATE_AUDIO_COUNTDOWN_2:
      case STATE_AUDIO_COUNTDOWN_4:
      case STATE_AUDIO_COUNTDOWN_6:
        call Leds.redOff();
        call LedsTimer.startOneShot( 300 );
        m_audio_state++;
        break;

      case STATE_AUDIO_COUNTDOWN_7:
        call Leds.redOff();
        post recordRecordTask();
        m_audio_state = STATE_AUDIO_RECORD_START;
        break;
    }
  }

  event void LedsTimer.fired() {
    recordCountdown();
  }

  task void recordStartTask() {
    if( call Spram.lock() ) {
      call Leds.yellowOff();
      if( m_audio_state == STATE_AUDIO_IDLE ) {
        m_audio_state = STATE_AUDIO_COUNTDOWN_START;
        m_speakerKeepAlive = FALSE;
      }
      if( m_audio_state == STATE_AUDIO_COUNTDOWN_START ) {
#ifndef PLAYRECORD_NO_SPEAKER
        if( call SpeakerPowerKeepAlive.isAlive() == FALSE ) {
          m_audio_state = STATE_AUDIO_COUNTDOWN_3;
          recordCountdown();
        }
        else if( call SpeakerPowerControl.stop() == SUCCESS )
          m_audio_state = STATE_AUDIO_COUNTDOWN_3;
        else
          post recordStartTask();
#else
        m_audio_state = STATE_AUDIO_COUNTDOWN_3;
        recordCountdown();
#endif
      }
    }
    else {
      post recordStartTask();
    }
  }

  task void recordRecordTask() {
    if( m_audio_state == STATE_AUDIO_RECORD_START ) {
      m_audio_state = STATE_AUDIO_RECORD_RECORDING;
      call Leds.redOn();
      atomic {
        m_micdest = samples();
        m_micnext = m_mic2;
      }
      memset( samples(), 0, NUM_SAMPLES );
      call Microphone.start( m_mic1, MIC_SAMPLES, (1024*1024L)/SAMPLING_RATE, TRUE );
    }
  }

  task void scaleAudio() {
    if( m_audio_state == STATE_AUDIO_SCALE ) {
      uint8_t* p;
      const uint8_t* pEnd;
      uint8_t maxval = samples()[0];
      uint8_t minval = samples()[0];

      for( p=samples(),pEnd=samples()+NUM_SAMPLES; p!=pEnd; p++ ) {
        if( *p > maxval ) maxval = *p;
        if( *p < minval ) minval = *p;
      }

      if( maxval > minval ) {
        uint16_t k = (2U*SCALED_AMPLITUDE * 256U) / (maxval - minval);
        for( p=samples(); p!=pEnd; p++ )
          *p = ((k * (*p - minval)) >> 8) + (128 - SCALED_AMPLITUDE);
      }

      call Leds.redOff();
      m_audio_state = STATE_AUDIO_IDLE;
      call Spram.publish( NUM_SAMPLES );
    }
  }

  task void recordStopTask() {
    if( m_audio_state == STATE_AUDIO_RECORD_RECORDING ) {
      m_audio_state = STATE_AUDIO_SCALE;
      post scaleAudio();
    }
  }

  async event result_t Microphone.repeat( void* addr, uint16_t length ) {

#if 1
    void* addrEnd;

    call Microphone.repeatStart( m_micnext, length );

    m_micnext = (uint16_t*)addr;
    addrEnd = ((uint16_t*)addr) + MIC_SAMPLES;

    while( addr != addrEnd )
      *m_micdest++ = *((uint16_t*)addr)++ >> 4;

    if( m_micdest >= (samples() + NUM_SAMPLES) )
      return FAIL;

    return SUCCESS;
#else
    return FAIL;
#endif
  }

  async event void Microphone.done( void* addr, uint16_t length ) {
    post recordStopTask();
  }


#ifndef PLAYRECORD_NO_SPEAKER
  // Play

  task void playStartTask() {
    if( m_audio_state == STATE_AUDIO_IDLE ) {
      if( call Spram.isValid() ) {
        m_audio_state = STATE_AUDIO_PLAY_PLAYING;
        m_speakerKeepAlive = TRUE;
        call Leds.greenOn();
        call Speaker.start( samples(), call Spram.getSizeBytes(), FALSE, (1024*1024L)/SAMPLING_RATE, FALSE );
      }
    }
  }

  task void playStopTask() {
    if( m_audio_state == STATE_AUDIO_PLAY_PLAYING ) {
      m_audio_state = STATE_AUDIO_IDLE;
      call Leds.greenOff();
    }
  }

  event void Speaker.started( void* addr, uint16_t length, result_t result ) {
  }

  async event void Speaker.done( void* addr, uint16_t length, bool repeat ) {
    if( addr == samples() )
      post playStopTask();
  }

  async event void Speaker.repeat( void* addr, uint16_t length ) {
  }


  // Speaker 

  event void SpeakerPowerKeepAlive.shutdown() {
    if( m_speakerKeepAlive )
      call SpeakerPowerKeepAlive.keepAlive();
  }

  event void SpeakerPowerControl.started() {
  }

  event void SpeakerPowerControl.stopped() {
    recordCountdown();
  }
#endif


  // Button clicking

  async event void Button.multiClick( uint8_t count ) {
    switch( count ) {
#ifndef PLAYRECORD_NO_SPEAKER
      case 1: post playStartTask(); break;
#endif
      case 2: post recordStartTask(); break;
    }
  }

  async event void Button.longClick( uint32_t time ) {
  }


  // Spram

  event void Spram.locked() {
    call Leds.yellowOn();
  }

  event void Spram.updated() {
    call Leds.yellowOff();
  }

}

