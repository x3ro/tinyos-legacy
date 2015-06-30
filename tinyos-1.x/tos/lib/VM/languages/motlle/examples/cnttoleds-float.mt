// The usual test application: count to the leds
any i = 0.0;

// Counts at 1Hz.
settimer0(10);
any timer0()
{
  i = i + 1.0;
  led(truncate(i) & 7);
}
