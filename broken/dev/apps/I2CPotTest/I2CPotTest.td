configuration I2CPotTest {}

implementation {
  components Main, I2CPotTestM, I2CPotC, LedsC;

  Main.StdControl -> I2CPotTestM;
  I2CPotTestM.I2CPot -> I2CPotC;
  I2CPotTestM.Leds -> LedsC;
  I2CPotTestM.I2CControl -> I2CPotC;
}
