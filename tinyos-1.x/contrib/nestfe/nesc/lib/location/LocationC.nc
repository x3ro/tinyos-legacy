
/******
 * This module simply translates a real localization attribute
 * such as RssiLocalization into a virtual attribute simply called
 * Location.
 *****/

includes Registry;

configuration LocationC {
  provides interface StdControl;
}

implementation { 
  components  
    RegistryC,
    LocationM,
    LocationMuxM;

  StdControl = LocationMuxM;

  LocationMuxM.Input[ATTRIBUTE_GPSLOCATION] -> RegistryC.GpsLocation;
  LocationMuxM.InputBackend[ATTRIBUTE_GPSLOCATION] -> RegistryC.AttrBackend[ATTRIBUTE_GPSLOCATION];

  LocationMuxM.Input[ATTRIBUTE_TRUELOCATION] -> RegistryC.TrueLocation;
  LocationMuxM.InputBackend[ATTRIBUTE_TRUELOCATION] -> RegistryC.AttrBackend[ATTRIBUTE_TRUELOCATION];


}
