package net.tinyos.bvr;

public interface BVRConstants {
  public static final short AM_BVR_APP_MSG = 55;                 //0x37
  public static final short AM_BVR_BEACON_MSG = 56;               //0x38
  public static final short AM_BVR_COMMAND_MSG = 57;             //0x39
  public static final short AM_BVR_COMMAND_RESPONSE_MSG = 58;    //0x3A
  public static final short AM_LE_REVERSE_LINK_ESTIMATION_MSG = 59; //0x3B
  public static final short AM_BVR_LOG_MSG = 60;

  //Commands
  public static final short BVR_CMD_HELLO = 0;           //Ack:0 //just a message to acknowledge presence
  public static final short BVR_CMD_LED_ON = 1;          //Ack:1 //yellow led on       
  public static final short BVR_CMD_LED_OFF = 2;         //Ack:1 //yellow led off
  public static final short BVR_CMD_SET_ROOT_BEACON = 3; //Ack:1 //currently does nothing. args: byte_arg: root_id
  public static final short BVR_CMD_IS_ROOT_BEACON = 4;  //Ack:1 
  public static final short BVR_CMD_SET_COORDS = 5;      //Ack:1 //args: coords
  public static final short BVR_CMD_GET_COORDS = 6;      //Ack:1 //returnst: coords
  public static final short BVR_CMD_SET_RADIO_PWR = 7;   //Ack:1 //args: byte_arg  
  public static final short BVR_CMD_GET_RADIO_PWR = 8;   //Ack:1 //returns: byte_arg  
  public static final short BVR_CMD_GET_INFO = 9;        //Ack:1 //gets args.info
  public static final short BVR_CMD_GET_NEIGHBOR = 10;   //Ack:1 //args: byte_arg: index //retrieves information about 1 neighbor
  public static final short BVR_CMD_GET_NEIGHBORS = 11;  //Ack:1 //args: byte_arg: index //gets list of neighbors (partitioned, if > 9)
  public static final short BVR_CMD_GET_LINK_INFO = 12;  //Ack:1 //args: byte_arg: index //returns 
  public static final short BVR_CMD_GET_LINKS = 13;      //Ack:1 //args: byte_arg: index //returns list of links known (partitioned, if > 9)
  public static final short BVR_CMD_GET_ID = 14;         //Ack:1 //get the identity of the mote in reply
  public static final short BVR_CMD_GET_ROOT_INFO = 15;  //Ack:1 // args: byte_arg = index
  public static final short BVR_CMD_FREEZE = 16;         //Ack:1 //stop updating, expiring, broadcasting info
  public static final short BVR_CMD_RESUME = 17;         //Ack:1 //resume
  public static final short BVR_CMD_REBOOT = 18;         //Ack:0 //reboot the mote
  public static final short BVR_CMD_RESET = 19;          //Ack:0 //reboot the mote and clear eeprom
  public static final short BVR_CMD_READ_LOG = 20;       //Ack:1 //logline in reply 
  public static final short BVR_CMD_APP_ROUTE_TO = 30;   //Ack:1 //args: args.dest

  //Log Messages
  //Packets
  public static final short LOG_SEND_BEACON = 1;  
  public static final short LOG_RECEIVE_BEACON = 3;
  public static final short LOG_SEND_ROOT_BEACON = 2;
  public static final short LOG_RECEIVE_ROOT_BEACON = 4;
  public static final short LOG_SEND_LINK_INFO = 5;
  public static final short LOG_RECEIVE_LINK_INFO = 6;
  public static final short LOG_SEND_APP_MSG = 7;
  public static final short LOG_RECEIVE_APP_MSG = 8;
  //Link table
  public static final short LOG_ADD_LINK = 10;       //0x0A
  public static final short LOG_CHANGE_LINK = 11;    //0x0B
  public static final short LOG_DROP_LINK = 12;      //0x0C
  //Neighbor table (neighbor's coordinates)
  public static final short LOG_ADD_NEIGHBOR = 20;   //14
  public static final short LOG_CHANGE_NEIGHBOR = 21;//15
  public static final short LOG_DROP_NEIGHBOR = 22;  //16
  //State
  public static final short LOG_CHANGE_COORDS = 30;  //1E
  public static final short LOG_CHANGE_COORD = 31;   //1F
  //Routing
  public static final short LOG_ROUTE_START      = 39;  //27
  public static final short LOG_ROUTE_FAIL_STUCK_0 = 40;  //28
  public static final short LOG_ROUTE_FAIL_STUCK  = 42;  //2A
  public static final short LOG_ROUTE_FAIL_BEACON = 41; //29
  //public static final short LOG_ROUTE_SAME_COORDS = 42; //2A
  public static final short LOG_ROUTE_SUCCESS = 43;     //2B
  public static final short LOG_ROUTE_FAIL_NO_LOCAL_BUFFER = 44;  //2C
  public static final short LOG_ROUTE_FAIL_NO_QUEUE_BUFFER = 45;  //2D
  public static final short LOG_ROUTE_INVALID_STATUS = 46;     //2E
  public static final short LOG_ROUTE_TO_SELF        = 47;     //2F
  public static final short LOG_ROUTE_STATUS_NEXT_ROUTE = 38; //26
  public static final short LOG_ROUTE_BUFFER_ERROR = 37;      //25
  public static final short LOG_ROUTE_SENT_NORMAL_OK = 32;          //20
  public static final short LOG_ROUTE_SENT_FALLBACK_OK = 33;          //21
  public static final short LOG_ROUTE_RECEIVED_OK = 34;      //22
  public static final short LOG_ROUTE_RECEIVED_DUPLICATE = 35;  //23
  //Logging for Scoped Flood
  public static final short LOG_ROUTE_BCAST_START =        64;  //40
  public static final short LOG_ROUTE_STATUS_BCAST_RETRY = 65;  //41
  public static final short LOG_ROUTE_STATUS_BCAST_FAIL =  66;  //42
  public static final short LOG_ROUTE_SENT_BCAST_OK =      67;  //43
  public static final short LOG_ROUTE_RECEIVED_BCAST_OK =  68;  //44
  public static final short LOG_ROUTE_BCAST_END_SCOPE =    69;  //45
  public static final short LOG_ROUTE_BCAST_ERROR_TIMER_FAILED = 70;  //46
  public static final short LOG_ROUTE_BCAST_ERROR_TIMER_PENDING = 71; //47
  //Logging self logging
  public static final short LOG_LOGGER_STATS = 50;      //32
  public static final short LOG_UART_COMM_STATS = 51;   //33

  //Logging For QueuedSendM
  public static final short LOG_LRX_SEND = 101;
  public static final short LOG_LRX_RECEIVE = 102;
  public static final short LOG_LRX_SXFER_START = 103;
  public static final short LOG_LRX_SXFER_FINISH = 104;
  public static final short LOG_LRX_RXFER_START = 105;
  public static final short LOG_LRX_RXFER_FINISH = 106;

  //Logging temporary - for debugging
  public static final short LOG_DBG1 = 129;         //81
  public static final short LOG_DBG2 = 130;         //82
  public static final short LOG_DBG3 = 131;         //83

  //Logging for retransmit test
  public static final short LOG_ROUTE_RETRANSMIT_SUCCESS = 132; //84
  public static final short LOG_ROUTE_RETRANSMIT_FAIL = 133; //85

  public static final short TOS_BCAST_ADDR = (short) 0xffff;
  public static final short TOS_UART_ADDR = (short) 0x007e;
  public static final short BASE_STATION_ADDRESS = (short) 0x0000;


}
