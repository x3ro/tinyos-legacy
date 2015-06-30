any n = 0;
settimer0(5);
any timer0()
{ 
  n = (n + 1) & 7;
  led(n);
}
