
module PlayToneP {
  provides interface Init;
  provides interface PlayTone;
  uses interface Speaker;
  uses interface Timer2<TMilli> as Timer;
}
implementation {

// PLAYTONE_AMPLITUDE valid from 0 to 128, 0=silence, 128=maxvolume
#ifndef PLAYTONE_AMPLITUDE
#define PLAYTONE_AMPLITUDE 8
#endif

// PA, macro to scale a sine wave sample, with rounding
#define PA(a) ( ((( ((a)-128) *(PLAYTONE_AMPLITUDE))+64)/128) +128)

  static const uint8_t m_sine256[256] = { PA(128), PA(131), PA(134), PA(137),
  PA(140), PA(143), PA(146), PA(149), PA(152), PA(155), PA(158), PA(162),
  PA(165), PA(167), PA(170), PA(173), PA(176), PA(179), PA(182), PA(185),
  PA(188), PA(190), PA(193), PA(196), PA(198), PA(201), PA(203), PA(206),
  PA(208), PA(211), PA(213), PA(215), PA(218), PA(220), PA(222), PA(224),
  PA(226), PA(228), PA(230), PA(232), PA(234), PA(235), PA(237), PA(238),
  PA(240), PA(241), PA(243), PA(244), PA(245), PA(246), PA(248), PA(249),
  PA(250), PA(250), PA(251), PA(252), PA(253), PA(253), PA(254), PA(254),
  PA(254), PA(255), PA(255), PA(255), PA(255), PA(255), PA(255), PA(255),
  PA(254), PA(254), PA(254), PA(253), PA(253), PA(252), PA(251), PA(250),
  PA(250), PA(249), PA(248), PA(246), PA(245), PA(244), PA(243), PA(241),
  PA(240), PA(238), PA(237), PA(235), PA(234), PA(232), PA(230), PA(228),
  PA(226), PA(224), PA(222), PA(220), PA(218), PA(215), PA(213), PA(211),
  PA(208), PA(206), PA(203), PA(201), PA(198), PA(196), PA(193), PA(190),
  PA(188), PA(185), PA(182), PA(179), PA(176), PA(173), PA(170), PA(167),
  PA(165), PA(162), PA(158), PA(155), PA(152), PA(149), PA(146), PA(143),
  PA(140), PA(137), PA(134), PA(131), PA(128), PA(124), PA(121), PA(118),
  PA(115), PA(112), PA(109), PA(106), PA(103), PA(100), PA(97), PA(93), PA(90),
  PA(88), PA(85), PA(82), PA(79), PA(76), PA(73), PA(70), PA(67), PA(65),
  PA(62), PA(59), PA(57), PA(54), PA(52), PA(49), PA(47), PA(44), PA(42),
  PA(40), PA(37), PA(35), PA(33), PA(31), PA(29), PA(27), PA(25), PA(23),
  PA(21), PA(20), PA(18), PA(17), PA(15), PA(14), PA(12), PA(11), PA(10),
  PA(9), PA(7), PA(6), PA(5), PA(5), PA(4), PA(3), PA(2), PA(2), PA(1), PA(1),
  PA(1), PA(0), PA(0), PA(0), PA(0), PA(0), PA(0), PA(0), PA(1), PA(1), PA(1),
  PA(2), PA(2), PA(3), PA(4), PA(5), PA(5), PA(6), PA(7), PA(9), PA(10),
  PA(11), PA(12), PA(14), PA(15), PA(17), PA(18), PA(20), PA(21), PA(23),
  PA(25), PA(27), PA(29), PA(31), PA(33), PA(35), PA(37), PA(40), PA(42),
  PA(44), PA(47), PA(49), PA(52), PA(54), PA(57), PA(59), PA(62), PA(65),
  PA(67), PA(70), PA(73), PA(76), PA(79), PA(82), PA(85), PA(88), PA(90),
  PA(93), PA(97), PA(100), PA(103), PA(106), PA(109), PA(112), PA(115),
  PA(118), PA(121), PA(124) };

  static const uint8_t m_sine128[128] = { PA(128), PA(134), PA(140), PA(146),
  PA(152), PA(158), PA(165), PA(170), PA(176), PA(182), PA(188), PA(193),
  PA(198), PA(203), PA(208), PA(213), PA(218), PA(222), PA(226), PA(230),
  PA(234), PA(237), PA(240), PA(243), PA(245), PA(248), PA(250), PA(251),
  PA(253), PA(254), PA(254), PA(255), PA(255), PA(255), PA(254), PA(254),
  PA(253), PA(251), PA(250), PA(248), PA(245), PA(243), PA(240), PA(237),
  PA(234), PA(230), PA(226), PA(222), PA(218), PA(213), PA(208), PA(203),
  PA(198), PA(193), PA(188), PA(182), PA(176), PA(170), PA(165), PA(158),
  PA(152), PA(146), PA(140), PA(134), PA(128), PA(121), PA(115), PA(109),
  PA(103), PA(97), PA(90), PA(85), PA(79), PA(73), PA(67), PA(62), PA(57),
  PA(52), PA(47), PA(42), PA(37), PA(33), PA(29), PA(25), PA(21), PA(18),
  PA(15), PA(12), PA(10), PA(7), PA(5), PA(4), PA(2), PA(1), PA(1), PA(0),
  PA(0), PA(0), PA(1), PA(1), PA(2), PA(4), PA(5), PA(7), PA(10), PA(12),
  PA(15), PA(18), PA(21), PA(25), PA(29), PA(33), PA(37), PA(42), PA(47),
  PA(52), PA(57), PA(62), PA(67), PA(73), PA(79), PA(85), PA(90), PA(97),
  PA(103), PA(109), PA(115), PA(121) };

  static const uint8_t m_sine64[64] = { PA(128), PA(140), PA(152), PA(165),
  PA(176), PA(188), PA(198), PA(208), PA(218), PA(226), PA(234), PA(240),
  PA(245), PA(250), PA(253), PA(254), PA(255), PA(254), PA(253), PA(250),
  PA(245), PA(240), PA(234), PA(226), PA(218), PA(208), PA(198), PA(188),
  PA(176), PA(165), PA(152), PA(140), PA(128), PA(115), PA(103), PA(90),
  PA(79), PA(67), PA(57), PA(47), PA(37), PA(29), PA(21), PA(15), PA(10),
  PA(5), PA(2), PA(1), PA(0), PA(1), PA(2), PA(5), PA(10), PA(15), PA(21),
  PA(29), PA(37), PA(47), PA(57), PA(67), PA(79), PA(90), PA(103), PA(115) };

  static const uint8_t m_sine32[32] = { PA(128), PA(152), PA(176), PA(198),
  PA(218), PA(234), PA(245), PA(253), PA(255), PA(253), PA(245), PA(234),
  PA(218), PA(198), PA(176), PA(152), PA(128), PA(103), PA(79), PA(57), PA(37),
  PA(21), PA(10), PA(2), PA(0), PA(2), PA(10), PA(21), PA(37), PA(57), PA(79),
  PA(103) };

  static const uint8_t m_sine16[16] = { PA(128), PA(176), PA(218), PA(245),
  PA(255), PA(245), PA(218), PA(176), PA(128), PA(79), PA(37), PA(10), PA(0),
  PA(10), PA(37), PA(79) };

  static const uint8_t m_sine8[8] = { PA(128), PA(218), PA(255), PA(218),
  PA(128), PA(37), PA(0), PA(37) };

  static const uint8_t m_sine4[4] = { PA(128), PA(255), PA(128), PA(0) };

  static const uint8_t m_sine2[2] = { PA(255), PA(0) };

  static const uint8_t* m_sines[] = { m_sine2, m_sine4, m_sine8, m_sine16,
  m_sine32, m_sine64, m_sine128, m_sine256 };


  const uint8_t* m_userSine;
  uint16_t m_userFreq;
  uint16_t m_userDur;

  command result_t Init.init() {
    m_userSine = NULL;
    m_userFreq = 0;
    return SUCCESS;
  }

  // freqHz must be between 43 Hz and 11000 Hz, inclusive.
  command result_t PlayTone.start( uint16_t freqHz, uint16_t durMilli ) {
    return call PlayTone.startAt( call Timer.getNow(), freqHz, durMilli );
  }

  command result_t PlayTone.startAt( uint32_t t0, uint16_t freqHz, uint16_t durMilli ) {
    if( m_userSine == NULL ) {

      // For the given freqHz, calculate a playback rate between 11000 Hz and
      // 22000 Hz and an appropriate precalculated sine wave.

      // Sample period is 95us for 11000 Hz and 47us for 22000 Hz.

      uint16_t cycles = freqHz ? ((11000 + freqHz/2) / freqHz) : 0;
      uint16_t bits = 0;
      uint16_t rateHz = freqHz;
      uint16_t length = 1;
      bool playing = FALSE;
      const uint8_t* sine = NULL;

      while( cycles ) {
        cycles >>= 1;
        bits++;
        rateHz <<= 1;
        length <<= 1;
      }

      if( (bits >= 1) && (bits <= 8) ) {
        uint32_t samplePeriod = 1024*1024L + rateHz/2; //round
        samplePeriod /= rateHz;
        sine = m_sines[bits-1];
        playing = call Speaker.start( (void*)sine, length, FALSE, samplePeriod, TRUE );
      }
      else {
        freqHz = 0;
        playing = TRUE;
      }

      if( playing ) {
        m_userSine = sine;
        m_userFreq = freqHz;
        m_userDur = durMilli;
        if( durMilli )
          call Timer.startOneShotAt( t0, durMilli );
        return SUCCESS;
      }
    }
    return FAIL;
  }

  void done() {
    uint16_t freqHz = m_userFreq;
    uint16_t durMilli = m_userDur;
    m_userSine = NULL;
    m_userFreq = 0;
    m_userDur = 0;
    signal PlayTone.done( freqHz, durMilli );
  }

  task void doneTask() {
    done();
  }

  result_t stop() {
    if( m_userSine != NULL ) {
      call Speaker.stop();
      return SUCCESS;
    }
    else if( m_userFreq == 0 ) {
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t PlayTone.stop() {
    if( stop() ) {
      call Timer.stop();
      post doneTask();
      return SUCCESS;
    }
    return FAIL;
  }

  event void Speaker.started( void* addr, uint16_t length, result_t result ) {
    //if( m_userSine == addr )
      signal PlayTone.started( m_userFreq, m_userDur );
  }

  async event void Speaker.done( void* addr, uint16_t length, bool repeat ) {
    //if( m_userSine == addr )
      post doneTask();
  }

  async event void Speaker.repeat( void* addr, uint16_t length ) {
  }

  event void Timer.fired() {
    if( stop() )
      done();
  }
}

