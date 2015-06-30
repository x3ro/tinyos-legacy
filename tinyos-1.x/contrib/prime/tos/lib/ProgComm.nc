includes ProgCommMsg;

configuration ProgComm {
    provides {
	interface StdControl;
    }
}

implementation
{
    components ProgCommM, Logger, GenericComm, LedsC, HPLBootloader;

    StdControl = ProgCommM;
    ProgCommM.Send -> GenericComm.SendMsg[AM_WRITEFRAG];
    ProgCommM.GenericCommCtl -> GenericComm;
    ProgCommM.LoggerCtl -> Logger;
    ProgCommM.LoggerWrite -> Logger;
    ProgCommM.LoggerRead -> Logger;
    
    ProgCommM.ReadFragmentMsg -> GenericComm.ReceiveMsg[AM_READFRAG];
    ProgCommM.WriteFragmentMsg -> GenericComm.ReceiveMsg[AM_WRITEFRAG];
    ProgCommM.NewProgramMsg -> GenericComm.ReceiveMsg[AM_NEWPROG];
    ProgCommM.StartReprogrammignMsg -> GenericComm.ReceiveMsg[AM_STARTPROG];
    ProgCommM.Leds -> LedsC.Leds;
    ProgCommM.Bootloader -> HPLBootloader.Bootloader;
}
