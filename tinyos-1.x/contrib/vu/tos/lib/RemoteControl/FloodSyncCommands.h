/*
 * Author: Brano Kusy
 * Date last modified: May04
 */
typedef struct FloodSyncCommandsPoll
{
	uint16_t	senderAddr;
	uint16_t	sendTo;
	uint16_t	msgID;
}FloodSyncCommandsPoll;
typedef struct {
	uint8_t nodeID;
	uint8_t msgID;
} data_token;

enum{
	AM_FLOODSYNCCMDPOLL = 0xBD,
	FLOODSYNC_CTLID = 0x36,
	FLOODSYNCCMD_ID = 0x02,
    FLOODSYNCCMD_LEN = sizeof(data_token),
	FLOODSYNCCMDPOLL_LEN = sizeof(FloodSyncCommandsPoll)
};



