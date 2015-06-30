/*
 * Basic communication codes for running through the UART
 */

enum {
  MSG_TYPE_COMMAND = 1,
  MSG_TYPE_RADIO   = 2,
  MSG_TYPE_RESPONSE = 1
};

enum {
  MSG_COMMAND_GET  = 0,
  MSG_COMMAND_SET  = 1
};

enum {
  MSG_ARG_RF_STATS      = 0,   // Get only
  MSG_ARG_RF_CHANNEL    = 1,
  MSG_ARG_RF_STATE      = 2,   // Get only
  MSG_ARG_CHIPCON_STATE = 3,
  MSG_ARG_ID            = 4,   // Get only
};

