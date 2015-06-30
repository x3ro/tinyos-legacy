
configuration SyncAlarmC
{
	provides
	{
		interface StdControl;
		interface SyncAlarm<uint32_t> as Alarm[uint8_t timer];
	}
}
implementation
{
	components SyncAlarmM,
	           LocalTimeM,
	           InitHCS08TimerC,
	           HPLTimer2M;

	StdControl = SyncAlarmM;
	Alarm = SyncAlarmM;

	SyncAlarmM.LocalTime -> LocalTimeM.LocalTime;
	SyncAlarmM.HPLTimer -> HPLTimer2M.HPLTimer;
	LocalTimeM.HPLTimer -> HPLTimer2M.HPLTimer;
}
