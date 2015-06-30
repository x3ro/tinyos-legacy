/*
 * Author: Brano Kusy, kusy@isis.vanderbilt.edu
 * Date last modified: Jan05
 */

typedef struct TimeSyncPoll
{
	uint16_t	senderAddr;
	uint16_t	msgID;
}TimeSyncPoll;

enum
{
	AM_TIMESYNCPOLL = 0xBA,
	AM_DIAGMSG = 0xB1,
	TIMESYNCPOLL_LEN = sizeof(TimeSyncPoll),
};

