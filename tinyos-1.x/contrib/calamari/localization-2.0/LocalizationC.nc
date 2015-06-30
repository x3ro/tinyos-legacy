
/******
 * This module simply translates a real localization attribute
 * such as RssiLocalization into a virtual attribute simply called
 * Location.
 *****/

includes Registry;
includes Localization;

configuration LocalizationC {
  provides interface StdControl;
}

implementation { 
  components  
    RegistryC,
    LocationMuxM;

  StdControl = LocationMuxM;

  LocationMuxM.Input[ATTRIBUTE_RSSILOCATION] -> RegistryC.RssiLocation;
  LocationMuxM.InputBackend[ATTRIBUTE_RSSILOCATION] -> RegistryC.AttrBackend[ATTRIBUTE_RSSILOCATION];


}
