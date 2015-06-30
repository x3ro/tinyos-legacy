any samples = 10, current = 0;
any readings = make_vector(samples);

if (id()) settimer0(2);
else settimer0(0);

any timer0()
{
  readings[current++ % samples] = light();
  if (current % samples == 0)
    send_data(readings);
}

any send_data(data)
{
  led(l_blink | l_yellow);
  send(-1, encode(vector(id(), current, 0, encode(readings))));
}
