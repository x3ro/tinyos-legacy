/** Interface to send notification events when the time sync module changes the time
*/
includes TosTime;
interface NotifyTimeChange {
	/** Time Sync module changed the time to be cur_time */
	event void timeChanged(tos_time_t cur_time);
}