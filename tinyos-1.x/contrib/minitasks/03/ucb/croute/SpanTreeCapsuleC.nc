configuration SpanTreeCapsuleC {
  provides {
    interface ERoute[uint8_t type];
    interface StdControl;
  }
}
implementation {

  components SpanTreeCapsuleM, SpanTreeC;
  StdControl = SpanTreeC.StdControl;
  ERoute = SpanTreeCapsuleM.InERoute;
  SpanTreeCapsuleM.ERoute -> SpanTreeC.ERoute;
}
