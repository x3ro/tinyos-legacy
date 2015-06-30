includes Router;

configuration MultiHopRouterC {

}
implementation {
  components MultiHopRouterM;
  
  components new AMSender(AM_ROUTE);
  components new AMReceiver(AM_ROUTE);
  components new AMSnooper(AM_ROUTE);
  components new AMController(AM_ROUTE);

  MultiHopRouterM.SubControl -> AMController;
  MultiHopRouterM.Receive -> AMReceiver;
  MultiHopRouterM.Snoop -> AMSnooper;
  MultiHopRouterM.Send -> AMSender;
  
}
