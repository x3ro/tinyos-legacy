//!! Config 36 { uint8_t TinySecTransmitMode = 1; }
//!! Config 37 { uint8_t TinySecReceiveMode = 1; }

module TSTestAppM
{
   uses interface TinySecMode;
   uses interface Config_TinySecTransmitMode;
   uses interface Config_TinySecReceiveMode;
}
implementation
{

  event void Config_TinySecTransmitMode.updated()
  {
    if(G_Config.TinySecTransmitMode == 1)
      call TinySecMode.setTransmitMode(TINYSEC_AUTH_ONLY);
    else if(G_Config.TinySecTransmitMode == 2)
      call TinySecMode.setTransmitMode(TINYSEC_ENCRYPT_AND_AUTH);
    else
      call TinySecMode.setTransmitMode(TINYSEC_DISABLED);
  }

  event void Config_TinySecReceiveMode.updated()
  {
    if(G_Config.TinySecReceiveMode == 1)
      call TinySecMode.setReceiveMode(TINYSEC_RECEIVE_AUTHENTICATED);
    else if(G_Config.TinySecReceiveMode == 2)
      call TinySecMode.setReceiveMode(TINYSEC_RECEIVE_CRC);
    else
      call TinySecMode.setReceiveMode(TINYSEC_RECEIVE_ANY);
  }

}
