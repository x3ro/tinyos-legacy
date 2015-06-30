includes SocialMsg;
configuration Social { }
implementation
{
  components Main, SocialM, GenericComm as Comm, Checkpoint, IdentC, TimerC;
  components PotC, LedsC, RangeC, EEPROM;

  Main.StdControl -> SocialM;

  SocialM.SubControl -> IdentC;
  SocialM.SubControl -> Comm;
  SocialM.SubControl -> TimerC;

  SocialM.CheckpointInit -> Checkpoint;
  SocialM.CheckpointRead -> Checkpoint;
  SocialM.CheckpointWrite -> Checkpoint;

  SocialM.Ident -> IdentC;
  SocialM.Timer -> TimerC.Timer[unique("Timer")];
  SocialM.Pot -> PotC;
  SocialM.Leds -> LedsC;

  SocialM.SendSocialMsg -> Comm.SendMsg[AM_DATAMSG];
  SocialM.ReceiveIdMsg -> Comm.ReceiveMsg[AM_IDENTMSG];
  SocialM.ReceiveReqDataMsg -> Comm.ReceiveMsg[AM_REQDATAMSG];
  SocialM.ReceiveRegisterMsg -> Comm.ReceiveMsg[AM_REGISTERMSG];

  IdentC.Leds -> LedsC;
  IdentC.Timer -> TimerC.Timer[unique("Timer")];
  IdentC.SendIdMsg -> Comm.SendMsg[AM_IDENTMSG];
  IdentC.ReceiveIdMsg -> Comm.ReceiveMsg[AM_IDENTMSG];
  IdentC.Range -> RangeC;

  Checkpoint.EEPROMRead -> EEPROM;
  Checkpoint.EEPROMWrite -> EEPROM.EEPROMWrite[unique("EEPROMWrite")];
  Checkpoint.EEPROMControl -> EEPROM;
}

