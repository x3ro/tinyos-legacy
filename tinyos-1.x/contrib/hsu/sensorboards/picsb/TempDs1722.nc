// $

/*  TEMP_INIT command initializes the MSSP as I2C*/
/*  TEMP_GET_DATA command initiates acquiring a reading from Microchip TCN75A temperature I2C sensor*/
/*  TEMP_DATA_READY is signaled, providing data, when it becomes available*/


configuration TempDS1722
{
  provides interface ADC as TempADC;
  provides interface StdControl;
}
implementation
{
  components TempDS1722M, SPIPacketC as SPI;

  StdControl = TempDS1722M;
  TempADC = TempDS1722M;

  TempDS1722M.SPIControl -> SPI;
  TempDS1722M.SPIPacket -> SPI;
}
