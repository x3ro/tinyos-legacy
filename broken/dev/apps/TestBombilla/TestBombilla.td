includes BombillaMsgs;

configuration TestBombilla { }
implementation
{
  components Main, Bombilla, TimerC, LedsC, Photo, Temp, GenericComm;
  components PotC, RandomLFSR, Narpro, AMStandard;
  components BStacks, BBuffer, BLocksSafe, BSynch, BInstruction, BQueue;

  Main.StdControl -> Bombilla;
  Main.StdControl -> Narpro;

  Bombilla.StdControlPhoto -> Photo.StdControl;
  Bombilla.StdControlTemp  -> Temp.StdControl;
//  Bombilla.StdControlAccel -> Accel.StdControl;
//  Bombilla.StdControlEEPROM -> EEPROM.StdControl;
  Bombilla.StdControlNetwork -> GenericComm.Control;

  Bombilla.Stacks -> BStacks.Stacks;
  BStacks.BombillaError -> Bombilla;

  Bombilla.Buffer -> BBuffer.Buffer;
  BBuffer.BombillaError -> Bombilla;

  Bombilla.Locks -> BLocksSafe.Locks;
  BLocksSafe.BombillaError -> Bombilla;

  Bombilla.Queue -> BQueue.Queue;
  BQueue.BombillaError -> Bombilla;

  Bombilla.Synch -> BSynch.Synch;
  BSynch.BombillaError -> Bombilla;
  BSynch.Locks -> BLocksSafe.Locks;

  Bombilla.networkActivity -> AMStandard.activity;
  
  Bombilla.Instruction -> BInstruction.Instruction;

  Bombilla.ClockTimer -> TimerC.Timer[unique("Timer")];
  Bombilla.PropagateTimer -> TimerC.Timer[unique("Timer")];
  Bombilla.TimeoutTimer -> TimerC.Timer[unique("Timer")];

  Bombilla.Leds -> LedsC;
  Bombilla.Random -> RandomLFSR;
  Bombilla.Pot -> PotC;

  Bombilla.PhotoADC -> Photo;
  Bombilla.TempADC -> Temp;
//  Bombilla.AccelXADC -> Accel.AccelX;
//  Bombilla.AccelYADC -> Accel.AccelY;
   
  Bombilla.SendCapsule -> GenericComm.SendMsg[AM_BOMBILLACAPSULEMSG];
  Bombilla.SendPacket -> GenericComm.SendMsg[AM_BOMBILLAPACKETMSG];
  Bombilla.SendError -> GenericComm.SendMsg[AM_BOMBILLAERRORMSG];

  Bombilla.ReceiveCapsule -> GenericComm.ReceiveMsg[AM_BOMBILLACAPSULEMSG];
  Bombilla.ReceivePacket ->  GenericComm.ReceiveMsg[AM_BOMBILLAPACKETMSG];
  
  Bombilla.sendDone <- GenericComm.sendDone;

  Bombilla.SendAdHoc -> Narpro.SendData;
  Bombilla.isAdHocActive -> Narpro.active;

}
