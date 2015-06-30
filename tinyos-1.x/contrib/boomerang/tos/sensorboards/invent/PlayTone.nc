
interface PlayTone {
  command result_t start( uint16_t freqHz, uint16_t durMilli );
  command result_t stop();
  event void started( uint16_t freqHz, uint16_t durMilli );
  event void done( uint16_t freqHz, uint16_t durMilli );

  command result_t startAt( uint32_t t0, uint16_t freqHz, uint16_t durMilli );
}

