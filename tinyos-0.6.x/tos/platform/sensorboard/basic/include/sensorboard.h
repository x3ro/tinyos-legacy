ALIAS_OUTPUT_ONLY_PIN(PHOTO_CTL, PW1); 
ALIAS_OUTPUT_ONLY_PIN(TEMP_CTL, PW2);
#if defined (__AVR_ATmega163__)
#define PHOTO_PORT 1  /* TOS_ADC_PORT_1 */
#define TEMP_PORT  2  /* TOS_ADC_PORT_2 */
// #define VOLTAGE_PORT 30 /* moved to hardware.h */
#elif defined (__AVR_AT90S8535__)
#define PHOTO_PORT 1  /* TOS_ADC_PORT_1 */
#define TEMP_PORT  2  /* TOS_ADC_PORT_2 */
/* no way to get voltage in RENE 1 */
#else
#define PHOTO_PORT 6  /* TOS_ADC_PORT_1 */
#define TEMP_PORT  5  /* TOS_ADC_PORT_2 */
// #define VOLTAGE_PORT 7 /* moved to hardware.h */
#endif
