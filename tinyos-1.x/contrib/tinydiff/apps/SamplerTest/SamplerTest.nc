//Mohammad Rahimi
includes Msg;

configuration SamplerTest { }
implementation {
    components Main, SamplerTestM, GenericComm as Comm,LedsC,SamplerC,TimerC;

    Main.StdControl -> SamplerTestM;
    SamplerTestM.Leds -> LedsC;
    SamplerTestM.TxManager -> TimerC.Timer[unique("Timer")];



    //Sampler Communication
    SamplerTestM.SamplerControl -> SamplerC.SamplerControl;
    SamplerTestM.Sample -> SamplerC.Sample;

    //RF communication facility
    SamplerTestM.CommControl -> Comm;
    SamplerTestM.SendMsg -> Comm.SendMsg[Sample_Packet];
    SamplerTestM.ReceiveMsg -> Comm.ReceiveMsg[Sample_Packet];    
}
