// AM Handlers
enum {
  AM_MOTORSTATE = 1,
  AM_MOTORQUERY = 2,
  AM_MOTORTRIM = 3,
  AM_MOTORMOVEMENT = 4,
  AM_MOTORKEEPALIVE = 5,
  AM_GPS = 6,
  AM_SONAR = 7,
};


////////////////////////////////////////
// Motor State Message Payload
////////////////////////////////////////
enum {
  MOTORSTATE_DISABLED = 0,
  MOTORSTATE_ENABLED = 1,
};

typedef struct MotorState {
  bool motorState;
} MotorState_t;


////////////////////////////////////////
// Motor Query Message Payload
////////////////////////////////////////
enum {
  MOTORQUERY_STATE = 0,
  MOTORQUERY_TRIM = 1,
  MOTORQUERY_MOVEMENT = 2,
};

typedef struct MotorQuery {
  uint8_t type;
} MotorQuery_t;


////////////////////////////////////////
// Motor Trim Message Payload
////////////////////////////////////////
typedef struct MotorTrim {
  int8_t turnATrim;
  int8_t turnBTrim;
  int8_t speedATrim;
  int8_t speedBTrim;
} MotorTrim_t;


////////////////////////////////////////
// Motor Movement Message Payload
////////////////////////////////////////
typedef struct MotorMovement {
  int8_t turnA;
  int8_t turnB;
  int8_t speedA;
  int8_t speedB;
} MotorMovement_t;


////////////////////////////////////////
// Motor Keep Alive Message Payload
////////////////////////////////////////
typedef struct MotorKeepAlive {
  uint32_t stayAliveMillis;
} MotorKeepAlive_t;
