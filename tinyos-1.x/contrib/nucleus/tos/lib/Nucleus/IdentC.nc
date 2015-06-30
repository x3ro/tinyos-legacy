//$Id: IdentC.nc,v 1.8 2005/06/14 18:10:10 gtolle Exp $

includes Ident;

/**
 * This component provides basic identity information through Nucleus
 * Attributes.  
 *
 * @author Gilman Tolle
 */
configuration IdentC {
  provides interface StdControl;
} 
implementation {
  
  components
    IdentM,
    LedsC;

#if defined(PLATFORM_TELOSB)
  //  components DS2411C;
#endif

  StdControl = IdentM;

#if defined(PLATFORM_TELOSB)
  //  IdentM.DS2411->DS2411C;
#endif
}



