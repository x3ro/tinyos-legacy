//$Id: AttrsC.nc,v 1.5 2005/06/14 18:10:10 gtolle Exp $

includes Attrs;

/**
 * This component is the interchange point for named Nucleus Attributes.
 *
 * @author Gilman Tolle
 */

configuration AttrsC {
  provides {
    interface StdControl;
    interface AttrClient[AttrID id];
    interface AttrSetClient[AttrID id];
  }
  uses {
    interface AnyAttr[AttrID id];
    interface AnyAttrList[AttrID id];
    interface AnyAttrSet[AttrID id];
  }
}

implementation {
  
  components 
    AttrsM,
    AttrGenC;

  StdControl = AttrsM;

  AttrClient = AttrsM;
  AnyAttr = AttrsM;
  AnyAttrList = AttrsM;

  AttrSetClient = AttrsM;
  AnyAttrSet = AttrsM;
}

