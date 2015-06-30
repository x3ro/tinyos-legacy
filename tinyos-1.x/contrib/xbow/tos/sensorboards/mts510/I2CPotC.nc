/*
 *
 * Authors:		Alec Woo
 * Date last modified:  7/23/02
 *
 */

configuration I2CPotC
{
  provides 
  {
    interface StdControl;
    interface I2CPot;
  }
}

implementation 
{
  components I2CC, I2CPotM, LedsC;

  StdControl = I2CPotM;
  I2CPot = I2CPotM;
  I2CPotM.I2C -> I2CC;
  I2CPotM.I2CControl -> I2CC;
}
