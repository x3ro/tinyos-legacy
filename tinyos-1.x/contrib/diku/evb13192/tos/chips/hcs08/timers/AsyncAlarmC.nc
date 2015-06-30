
configuration AsyncAlarmC
{
	provides
	{
		interface StdControl;
		interface AsyncAlarm<uint32_t> as Alarm[uint8_t timer];
		interface LocalTime;
	}
	uses
	{
		interface Debug;
	}
}
implementation
{
	components AsyncAlarmM,
	           LocalTimeM,
	           HPLTimer2M;

	StdControl = AsyncAlarmM;
	Alarm = AsyncAlarmM;
	AsyncAlarmM = Debug;
	LocalTime = LocalTimeM.LocalTime;

	// LocalTimeM.HPLTimer MUST be wired before AsyncAlarmM.HPLTimer!!!
	LocalTimeM.HPLTimer -> HPLTimer2M.HPLTimer;
	AsyncAlarmM.LocalTime -> LocalTimeM.LocalTime;
	AsyncAlarmM.HPLTimer -> HPLTimer2M.HPLTimer;
}
