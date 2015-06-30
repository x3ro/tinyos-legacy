//$Id: LedsAttrC.nc,v 1.1 2005/06/19 01:53:20 cssharp Exp $

configuration LedsAttrC
{
  provides interface Attr<uint8_t> as Leds;
  provides interface AttrSet<uint8_t> as LedsSet;
}
implementation
{
  components LedsAttrM;
  components LedsC;

  Leds = LedsAttrM;
  LedsSet = LedsAttrM;

  LedsAttrM.Leds -> LedsC;
}

