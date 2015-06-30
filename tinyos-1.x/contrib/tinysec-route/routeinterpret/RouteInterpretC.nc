
includes rt2;

configuration RouteInterpretC
{
  provides interface StdControl;
}
implementation
{
  components RouteInterpretM
           , LedsC
	   , SpanTreeC
	   , RoutingC
	   ;

  StdControl = RouteInterpretM;
  StdControl = SpanTreeC;

  RouteInterpretM.Leds -> LedsC;
  RouteInterpretM.ERoute -> SpanTreeC;
  RouteInterpretM.AnswerSend -> RoutingC.RoutingSendByAddress[RT_ANSWER_HANDLER];
  RouteInterpretM.CmdRecv -> RoutingC.RoutingReceive[RT_CMD_MSG_HANDLER];
  
}

