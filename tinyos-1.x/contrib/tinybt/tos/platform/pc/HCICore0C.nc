configuration HCICore0C
{
     provides {
          interface Bluetooth; /* This is a bit tricky: We supply the Bluetooth interface for
				  our clients to use, but internally more interfaces 
				  are supplied... I guess this is not tricky, really, but it took
				  me a little bit to figure out... */
     }
}
implementation
{
     components HCICore0M, BTBasebandM, BTLMPM, BTLinkControllerM, BTSchedulerM, 
       BTFHChannelM,
       BTTaskSchedulerM /* The task scheduler implementation. */
       ;
     // StdControl = HCICore0M;
     /* Our external interface is provided byt the HCICore module */
     Bluetooth = HCICore0M;

     /* Set up the varios interfaces used between the components */
     BTTaskSchedulerM.BTBaseband -> BTBasebandM;
     BTTaskSchedulerM.BTHost     -> HCICore0M.BTHost;
     
     HCICore0M.TaskScheduler    -> BTTaskSchedulerM.BTTaskScheduler;
     HCICore0M.TaskSchedulerSig -> BTTaskSchedulerM.BTTaskSchedulerSig;
     HCICore0M.Baseband         -> BTBasebandM;
     HCICore0M.BTLMP            -> BTLMPM;
     HCICore0M.BTLinkController -> BTLinkControllerM;
     HCICore0M.BTHostSig        -> BTBasebandM;
     HCICore0M.BTHostSig        -> BTLMPM;

     BTBasebandM.TaskScheduler    -> BTTaskSchedulerM.BTTaskScheduler;
     BTBasebandM.BTFHChannel      -> BTFHChannelM;
     BTBasebandM.BTScheduler      -> BTSchedulerM;
     BTBasebandM.BTLinkController -> BTLinkControllerM;
     BTBasebandM.BTLMP            -> BTLMPM;
     BTBasebandM.BTHost           -> HCICore0M;

     BTLMPM.BTHost     -> HCICore0M;
     BTLMPM.BTBaseband -> BTBasebandM;

     BTLinkControllerM.BTBaseband -> BTBasebandM;
     BTLinkControllerM.BTLMP      -> BTLMPM;

     BTSchedulerM.BTLinkController -> BTLinkControllerM;
     BTSchedulerM.BTBaseband       -> BTBasebandM;

     BTFHChannelM.BTBaseband -> BTBasebandM;
}
