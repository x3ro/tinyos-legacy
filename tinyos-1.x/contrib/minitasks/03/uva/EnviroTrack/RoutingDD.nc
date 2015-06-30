

includes DirectedDiffusion;

configuration RoutingDD{
    provides{
    interface StdControl;
    interface RoutingSendByMobileID		;
    interface RoutingDDReceiveDataMsg	;
    interface Interest					;
    
    
    }
}

implementation{
    components  DirectedDiffusion;

    StdControl				= DirectedDiffusion;
    RoutingSendByMobileID	= DirectedDiffusion;
    RoutingDDReceiveDataMsg	= DirectedDiffusion;
    Interest				= DirectedDiffusion;


}
