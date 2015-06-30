module JoystickC {
  provides {
    interface StdControl;
    interface Joystick;
  }
}
implementation {
  norace uint8_t oldE, oldB, E, B;

  enum {
    BUTTONS_E = 1 << 2 | 1 << 3,
    BUTTONS_B = 1 << 4 | 1 << 6 | 1 << 7
  };

  command result_t StdControl.init() {
    // Enable pin change interrupts on PB4,6,7 and PE2,3
    outp(BUTTONS_B, PCMSK1);
    outp(BUTTONS_E, PCMSK0);

    // And pull those pins up
    outp(inp(PORTB) | BUTTONS_B, PORTB);
    outp(inp(PORTE) | BUTTONS_E, PORTE);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    // enable the pin-change interrupts, clear pending interrupts first
    oldE = oldB = 0xff; 
    outp(1 << PCIF0 | 1 << PCIF1, EIFR);
    outp(1 << PCIE0 | 1 << PCIE1, EIMSK);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    // disable the pin-change interrupts
    outp(0, EIMSK);
    return SUCCESS;
  }

  // Testing for a 1-0 transition on the pins seems to obviate the need
  // for timer-based debouncing (more by luck than judgment...)

#define ONE2ZERO(old, new, bit) (((old) & 1 << (bit)) && !((new) & 1 << (bit)))

  task void pinChange0() {
    uint8_t newE = E;

    // check PE2, 3 (left, right)
    if (ONE2ZERO(oldE, newE, 2))
      signal Joystick.move(3);
    if (ONE2ZERO(oldE, newE, 3))
      signal Joystick.move(1);

    oldE = newE;
  }
  
  task void pinChange1() {
    uint8_t newB = B;

    // check PB4, 6, 7 (center, top, bottom)
    if (ONE2ZERO(oldB, newB, 4))
      signal Joystick.fire();
    if (ONE2ZERO(oldB, newB, 6))
      signal Joystick.move(0);
    if (ONE2ZERO(oldB, newB, 7))
      signal Joystick.move(2);

    oldB = newB;
  }

  // We could conceivably lose some transitions if the interrupt triggers again
  // before the tasks run. But it doesn't seem to be a problem.
  // (If it is, something like: E &= inp(PINE), and resetting bits to one
  // in pinChangeN should fix it)
  TOSH_SIGNAL(SIG_PIN_CHANGE0) {
    E = inp(PINE);
    post pinChange0();
  }
  
  TOSH_SIGNAL(SIG_PIN_CHANGE1) {
    B = inp(PINB);
    post pinChange1();
  }
}
