any current = 0;
any readings = make_vector(10);
settimer0(10);
any timer0()
  {
    readings[current++ % 10] = temp();
    if (current % 10 == 0)
      {
	led(28);
	send(-1, encode(id(), current, 0, encode(readings)));
      }
  };
