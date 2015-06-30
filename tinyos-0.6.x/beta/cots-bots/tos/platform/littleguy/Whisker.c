/* 
 * Sarah Bergbreiter
 * 11/8/2001
 * COTS-BOTS
 *
 * This program debounces switch inputs and sends the resulting switch 
 * states over UART-compatible pin at 19200 baud after every change.
 * 
 * History:
 * 11/8/2001 - created.
 * 
 */

#include <io.h>
#include <hardware.h>

#define debounceTime 7
#define delayTime 4  // for 104us per bit -- 9600 baud

char swState[4];
char swCnt[4];

void delay(int cycles) {
  // 2 cycles to jump here + 2 cycles to jump back + 3 cycles per loop
  // + 1 cycle to set var -- each cycle is 4us
  while (cycles > 0)
    cycles--;
}  

void debug(void) {
  CLR_TX_PIN();
  delay(10);
  SET_TX_PIN();
}

void txState(void) {
  // Start bit (clear tx pin)
  int i;
  cli();   // disable interrupts
  // Send start bit
  CLR_TX_PIN();
  delay(delayTime);
  for (i = 0; i < 4; i++) {
    if (swState[i] == 1)
      CLR_TX_PIN();
    else
      SET_TX_PIN();
    delay(delayTime-2);
  }
  // Send 4 most significant bits as zeros
  CLR_TX_PIN();
  delay(delayTime);
  delay(delayTime);
  delay(delayTime);
  delay(delayTime);
  /*
  // Send 4 most significant bits as zeros
  //SET_TX_PIN();
  delay(delayTime);
  //CLR_TX_PIN();
  delay(delayTime);
  delay(delayTime);
  delay(delayTime);
  // Send data bit by bit with delay 104us per bit for 9600 baud
  for (i = 3; i > -1; i--) {
    //while (i > -1) {
    if (swState[i] == 1)
      CLR_TX_PIN();
    else
      SET_TX_PIN();
    delay(delayTime-2);
    //i--;
  }
  */
  // Stop bit (set tx pin)
  SET_TX_PIN();
  sei();   // re-enable interrupts
  return;
}

void checkPin(short pin) {
  char state = 0;
  if (swCnt[pin] > 0) {
    // Need this case statement because pins do not match hardware pins
    // (due to upper level software already written.
    if (pin == 0)
      state = 0x01 & (inp(PINB) >> 1);
    else if (pin == 1)
      state = 0x01 & inp(PINB);
    else if (pin == 2)
      state = 0x01 & (inp(PINB) >> 3);
    else if (pin == 3)
      state = 0x01 & (inp(PINB) >> 2);

    //state = 0x01 & (inp(PINB) >> pin);
    //delay(2);
    if (swState[pin] == state)
      swCnt[pin]--;
    else {
      //debug();
      swState[pin] = state;
      swCnt[pin] = 0;
      return;
    }

    if (swCnt[pin] == 0) {
      // Change State and send byte
      //if (state == 0)
      //prev_state = prev_state ^ (0x01 << pin);
      txState();
      //swCnt[pin] = -1;
    }
  }
}

SIGNAL(SIG_OVERFLOW0) {
  checkPin(0);
  checkPin(1);
  checkPin(2);
  checkPin(3);
}

int main(void) {

  // Initialize Variables here
  //char change;
  char pin0 = 0;
  char pin1 = 0;
  char pin2 = 0;
  char pin3 = 0;
  int i;

  // States start high (assuming that nothing is pressed)
  for (i = 0; i < 4; i++) {
    swState[i] = 1;
    swCnt[i] = 0;
  }

  // Set pin directions and internal pullups
  MAKE_SW0_INPUT();
  MAKE_SW1_INPUT();
  MAKE_SW2_INPUT();
  MAKE_SW3_INPUT();
  MAKE_TX_OUTPUT();

  SET_SW0_PIN();
  SET_SW1_PIN();
  SET_SW2_PIN();
  SET_SW3_PIN();
  SET_TX_PIN();

  // Set up interrupts and timer prescaler
  // TMR0 overflow will happen every 4ms for now  -- can change to 0.5ms
  outp(0x03, TCCR0);
  sbi(TIMSK, TOIE0);
  sei();

  // Main Loop
  while (1) {
    pin0 = READ_SW0_PIN();
    pin1 = READ_SW1_PIN();
    pin2 = READ_SW2_PIN();
    pin3 = READ_SW3_PIN();

    // Find which pin has changed
    if ((swCnt[0] == 0) & (swState[0] != pin0)) {
      swState[0] = pin0;
      swCnt[0] = debounceTime;
    }
    if ((swCnt[1] == 0) & (swState[1] != pin1)) {
      swState[1] = pin1;
      swCnt[1] = debounceTime;
    }
    if ((swCnt[2] == 0) & (swState[2] != pin2)) {
      swState[2] = pin2;
      swCnt[2] = debounceTime;
    }
    if ((swCnt[3] == 0) & (swState[3] != pin3)) {
      swState[3] = pin3;
      swCnt[3] = debounceTime;
    }
    // Maybe I should delay a bit here and not poll so fast?  Does it really
    // matter?
  }
}

