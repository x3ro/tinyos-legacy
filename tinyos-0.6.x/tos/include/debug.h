/******************************************************

  serial port and led debuging

  sp_debug implemented by lew girod
  led_debug implemented by naim busek

  note: may intefer with leds and UART if executed
      	concurrently

******************************************************/

#ifndef __LECS_H
#define __LECS_H

#ifdef DEBUG

typedef unsigned char byte;

static inline void wait(unsigned int dur) {
  for (; dur>0; dur--)
    asm volatile ("nop" ::);
}

//
//  serial port debugging
//

#ifdef SP_DEBUG
// ser port debugging
static inline void sp_dbg_init() {
  outp(12, UBRR);
  inp(UDR);
  outp(0x08,UART_CR);
  sei();
}

static inline void sp_dbg_dump_byte(char data) {
  sbi(UART_SR, TXC);
  outp(data, UDR);
}

// retained for backwards compatibility
// use readable function names above
static inline void ud_init() {
  outp(12, UBRR);
  inp(UDR); 
  outp(0x08,UART_CR);
  sei();
}
static inline void ud_byte(uint8_t data) {
	do {
		while ((inp(UART_SR) & 0x20)==0) {};
		outp(data, UDR);
	} while(0);
}

static inline void sp_init() {
  outp(12, UBRR);
  inp(UDR); 
  outp(0x08,UART_CR);
  sei();
}
static inline void sp_byte(char data) {
  sbi(UART_SR, TXC);
  outp(data, UDR);
}

#else
# define sp_dbg_init()
# define sp_dbg_dump_byte(x)
// retained for backwards compatibility
# define ud_init()
# define ud_byte(x)
# define sp_init()
# define sp_byte(x)
#endif // sp_debug


//
// led debugging
//

#ifdef LED_DEBUG
// led debuging

// this is to avoid confusion pulling pin low turns leds on
static inline void led_dbg_red_on(){
  CLR_RED_LED_PIN();
}
static inline void led_dbg_red_off(){
  SET_RED_LED_PIN();
}
static inline void led_dbg_red_toggle(){
  if(READ_RED_LED_PIN())
    CLR_RED_LED_PIN();
  else
    SET_RED_LED_PIN();
}
static inline void led_dbg_yellow_on(){
  CLR_YELLOW_LED_PIN();
}
static inline void led_dbg_yellow_off(){
  SET_YELLOW_LED_PIN();
}
static inline void led_dbg_yellow_toggle(){
  if(READ_YELLOW_LED_PIN())
    CLR_YELLOW_LED_PIN();
  else
    SET_YELLOW_LED_PIN();
}
static inline void led_dbg_green_on(){
  CLR_GREEN_LED_PIN();
}
static inline void led_dbg_green_off(){
  SET_GREEN_LED_PIN();
}
static inline void led_dbg_green_toggle(){
  if(READ_GREEN_LED_PIN())
    CLR_GREEN_LED_PIN();
  else
    SET_GREEN_LED_PIN();
}
static inline void led_dbg_all_on(){
  led_dbg_red_on();
  led_dbg_yellow_on();
  led_dbg_green_on();
}
static inline void led_dbg_all_off(){
  led_dbg_red_off();
  led_dbg_yellow_off();
  led_dbg_green_off();
}
static inline void led_dbg_init(){
  // DDR registers already set in hardware.h
  led_dbg_all_off();
}

#else //ndef LED_DEBUG

# define led_dbg_init()
# define led_dbg_all_on()
# define led_dbg_all_off()
# define led_dbg_red_on()
# define led_dbg_red_off()
# define led_dbg_red_toggle()
# define led_dbg_yellow_on()
# define led_dbg_yellow_off()
# define led_dbg_yellow_toggle()
# define led_dbg_green_on()
# define led_dbg_green_off()
# define led_dbg_green_toggle()
#endif //LED_DEBUG

#endif //DEBUG

#endif //__LECS_H
