
configuration ConfigStoreServiceC
{
  provides interface StdControl;
}
implementation
{
  components ConfigStoreServiceM
           , ConfigStoreC
	   , ConfigStoreCmdC
	   , NoLeds
	   ;

  StdControl = ConfigStoreServiceM;

  ConfigStoreServiceM.ConfigStoreControl -> ConfigStoreC;
  ConfigStoreServiceM.ConfigWrite -> ConfigStoreC;
  ConfigStoreServiceM.ConfigRead -> ConfigStoreC;
  ConfigStoreServiceM.ConfigStoreCmd -> ConfigStoreCmdC;

  ConfigStoreC.Leds -> NoLeds;
}

