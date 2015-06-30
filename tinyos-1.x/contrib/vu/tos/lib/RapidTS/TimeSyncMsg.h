/*
 * Author: Brano Kusy
 * Date last modified: Dec 04
 */

typedef struct{
	uint8_t		seqNum;		// sequence number for the root
	uint32_t    sendingTime;
} ts_data_token;

enum{
    ROUTING_BUFFER_SIZE = 200,
    TIMESYNC_ID = 0x03,
    TIMESYNC_TOKEN_SIZE = sizeof(ts_data_token),
};

