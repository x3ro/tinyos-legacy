// The usual test application: count to the leds
any i = 0;

// Counts at 1Hz.
settimer0(10);
any timer0()
{
  led(++i & 7);
}
