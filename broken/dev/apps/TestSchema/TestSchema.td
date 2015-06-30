configuration TestSchema {}
implementation
{
	components Main, AttrGlobal, AttrPhoto, AttrTemp, AttrPot, CommandLeds, ClockC, TestSchemaM, GenericComm, Attr, Command, CommandSounder, AttrAccel;
	Main.StdControl -> AttrGlobal;
	Main.StdControl -> AttrPhoto;
	Main.StdControl -> AttrTemp;
	Main.StdControl -> CommandLeds;
	Main.StdControl -> CommandSounder.StdControl;
	Main.StdControl -> AttrPot;
	Main.StdControl -> AttrAccel;
	Main.StdControl -> TestSchemaM;
	TestSchemaM.Clock -> ClockC;
	TestSchemaM.CommandUse -> Command;
	TestSchemaM.AttrUse -> Attr;
	TestSchemaM.SendMsg -> GenericComm.SendMsg[101];
	TestSchemaM.CommControl -> GenericComm.Control;
}
