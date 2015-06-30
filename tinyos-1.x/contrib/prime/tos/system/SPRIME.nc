// stand alone file to replace AMStandard.nc
// todo: invite interference flow incorrect? event process lags and whisper out of time. chirp with lower than 250 interval and/or short slot time will lose packets. generic base does not receive packets sent from PRIME. Implement transmission decision. remove debugging setting: only node 0 detects interference.

/*									tab:4
 * Authors:		Lin Gu
 * Date last modified:  12/1/02
 */

includes PktDef;

module SPRIME
{
  provides {
    interface StdControl as Control;
    
    // The interface are as parameterised by the active message id
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];

    // How many packets were received in the past second
    command uint16_t activity();
  }

  uses {
    // signaled after every send completion for components which wish to
    // retry failed sends
    event result_t sendDone();

    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;

    interface StdControl as RadioControl;
    interface BareSendMsgPrime as RadioSend;
    interface ReceiveMsg as RadioReceive;
    interface Leds;
    interface Timer as ActivityTimer;
    interface Timer as PrimeTimer;
    interface Timer as EffectiveSlotTimer;
    interface Pool;
    // interface RadioTiming;
    // interface ChannelMon;
    // interface Random;
  }
}

implementation
{
  // debug control
#define USE_LED

#define SIMULATIONno

#ifdef SIMULATION
#define DBG_DUMP_MSG
#endif

#define DEBUGGING

#include "common.h"
#include "VertConfig.inc"

  // #include "Debuging.h"

  //      Macros
#define min(x, y) ((x)>(y) ? (y) : (x))
#define max(x, y) ((x)>(y) ? (x) : (y))

#define inorder(x, y, z) ((unsigned long)((z)-(x)) > (unsigned long)((z)-(y)))
#define behind(x, y, lookahead) (inorder(x, y, y+lookahead))

#define GetMask(num_of_bits) ((1 << num_of_bits) - 1)
#define GetOffset(v, num_of_bits) (v & (GetMask(num_of_bits)))
#define NoToGroup(no, group_size) (no / group_size)
#define NoToGroupB(no, num_group_bits) (no >> num_group_bits)

#define AM_MAX_DATA_LENGTH (TOSH_DATA_LENGTH - 3);

  //#define NUM_TICK 128 /* number of ticks per second */
#define NUM_TICK 64 /* number of ticks per second */
#define TICK_TIME ((int)(1024/NUM_TICK)) /* number of miniseconds per tick */
#define ACCEPTABLE_CLOCK_ERROR 1
  // /////// #define TIME_SYNC_INTERVAL (((long)65536) / TICK_TIME /*+ (((TOS_LOCAL_ADDRESS<<7)-1) & 0xff)*/) /* need to consider more about the interval //////// */
#define TIME_SYNC_INTERVAL ((65536L / TICK_TIME) >> NUM_BIT_TICK_IN_SLOT)
#define NUM_BIT_TICK_IN_SLOT 4 /* The number of ticks in a slot must be an exponential to 2 */
#define GRACE_BEFORE 2
#define GRACE_AFTER 2
#define TICK_IN_SLOT_UNMASK (~(((unsigned long)(1<<NUM_BIT_TICK_IN_SLOT))-1))
#define SLOT_TICK (((unsigned long)1)<<NUM_BIT_TICK_IN_SLOT)
#define SLOT_TIME ((((unsigned long)1)<<NUM_BIT_TICK_IN_SLOT) * TICK_TIME)
#define MIN_WORK_TIME 1
#define GRACE_STOP_POINT (SLOT_TICK - GRACE_AFTER - MIN_WORK_TIME)
#define EFFECTIVE_SLOT_TIME (SLOT_TIME - (GRACE_BEFORE + GRACE_AFTER) * TICK_TIME)
#define MAX_GROUP_SIZE 1
#define NUM_BIT_SLOT_IN_SUPERSLOT 0
#define MIN_NUM_BIT_SUPERSLOT_IN_PERIOD 2
#define MAX_NUM_BIT_SUPERSLOT_IN_PERIOD 512
#define HIGHEST_TRANSMISSION_TIME 8
#define SYNC_SLOT_NO 0
#define INVITE_INTERFERENCE_SLOT_NO 1 /* /////// */
#define DETECT_INTERFERENCE_SLOT_NO 2 /* /////// */
#define PRM_TEST_LENGTH (0x80)
#define PRM_MAX_ISCORE 0x8 /* must be less than 42 */
#define PRM_HARD_ROTATION 4
#define PRM_HARD_LENGTH 4
#define PRM_HARD_NUM_LINE 1


  // Macros for the iterating sequence
#define ITERATION_MASK 0x3
#define GETi(m) ((int)(sqrt(2*m-1.5)+0.5))
#define GETj(m) (((int)(m - GETi(m)*(GETi(m)-1) / 2)) & ITERATION_MASK)

  // Macros for slot management
#define TickToAbsSlotNo(t) NoToGroupB(t, NUM_BIT_TICK_IN_SLOT)
#define TickToSlotNo(t) GetOffset(TickToAbsSlotNo(t), NUM_BIT_SLOT_IN_SUPERSLOT)
#define AbsSlotToAbsSuperSlotNo(t) NoToGroupB(t, NUM_BIT_SLOT_IN_SUPERSLOT)
#define AbsSlotToSuperSlotNo(t) GetOffset(AbsSlotToAbsSuperSlotNo(t), nNumBitSuperSlotInPeriod)
#define SlotToNumTick(s) (s << NUM_BIT_TICK_IN_SLOT)
#define AbsSuperSlotToPeriodNo(t) NoToGroupB(t, nNumBitSuperSlotInPeriod)
#define GET_PERIOD_NO(tic) NoToGroupB(tic, NUM_BIT_TICK_IN_SLOT+NUM_BIT_SLOT_IN_SUPERSLOT+nNumBitSuperSlotInPeriod)
#define AbsSuperSlotToTick(s) (s << (NUM_BIT_TICK_IN_SLOT + NUM_BIT_SLOT_IN_SUPERSLOT))
#define TickToAbsSuperSlotNo(t) (AbsSlotToAbsSuperSlotNo(TickToAbsSlotNo(t)))

#define PRIME_CONFIRM 0x66

#define PRIME_LOWER_ERROR 0x4
#define PRIME_CRITICAL 0X10

  // #define lllll /////// temp

#ifdef lllll
#define IS_CRITICAL 0
#define MARK_CRITICAL
#define UNMARK_CRITICAL

  // must remove UART info for release version
#define KNOCK
#define KNOCK0
#define KNOCK0FREE

#define LEAVE

#endif

#ifdef OLDLOCK

#define IS_CRITICAL (gcGeneralState & PRIME_CRITICAL)
#define MARK_CRITICAL gcGeneralState |= PRIME_CRITICAL
#define UNMARK_CRITICAL gcGeneralState &= (~PRIME_CRITICAL)

  // /////// temporary definition

  // must remove UART info for release version
#define KNOCK /*VAR(lNumKnock)++;*/ DIS_INTERRUPT; if (IS_CRITICAL) { EN_INTERRUPT; /* TOS_CALL_COMMAND(AM_YELLOW_LED_TOGGLE)(); VAR(yellow_toggle) = 10;  TOS_CALL_COMMAND(AM_DBG_SEND3)("RA", VAR(info), VAR(me)); VAR(lNumRace)++;*/ return;} else {MARK_CRITICAL; EN_INTERRUPT; lKnockThru++;}
#define KNOCK0 /*VAR(lNumKnock)++; */DIS_INTERRUPT; if (IS_CRITICAL) {EN_INTERRUPT; /* TOS_CALL_COMMAND(AM_YELLOW_LED_TOGGLE)();  VAR(yellow_toggle) = 10; TOS_CALL_COMMAND(AM_DBG_SEND3)("RC", VAR(info), VAR(me));  VAR(lNumRace)++; */ return 0;} else {MARK_CRITICAL; EN_INTERRUPT; lKnockThru++;}
#define KNOCKREC0(x) dMe = x; KNOCK0; dInfo = x;
#define KNOCKREC(x) dMe = x; KNOCK; dInfo = x;
#define KNOCK0FREE /* VAR(lNumKnock)++;*/ DIS_INTERRUPT; if (IS_CRITICAL) {EN_INTERRUPT; call Pool.free(data); /*VAR(lNumMemFreed)++; TOS_CALL_COMMAND(AM_YELLOW_LED_TOGGLE)();  VAR(yellow_toggle) = 10; TOS_CALL_COMMAND(AM_DBG_SEND3)("RC", VAR(info), VAR(me));  VAR(lNumRace)++; */ return 0;} else {MARK_CRITICAL; EN_INTERRUPT; lKnockThru++;}

#define LEAVE UNMARK_CRITICAL; dMe = dInfo = 0xffff;

#endif

  // Prime overall parameters
#define PRIME_EVENT_QUEUE_SIZE 0x31
  // msg queue size. must be a multiple of 8
#define PRIME_QUEUE_SIZE 0x18
#define PRIME_WAIT_TIME (NUM_TICK/2 + 1)
#define PRIME_EVENT_EXPIRE_TIME 0x150
#define PRIME_EVENT_CYCLE_TIME (PRIME_CLOCK_RATE * 10)
#define PRIME_EVENT_RETRY_DELAY 5
#define PRIME_INPUT_QUEUE_NUM 5
#define PRIME_INPUT_QUEUE_SIZE PRIME_QUEUE_SIZE
#define PRIME_INPUT_QUEUE_CSIZE (PRIME_INPUT_QUEUE_SIZE/(sizeof(char)))
#define PRIME_INPUT_QUEUE_BEHIND (PRIME_INPUT_QUEUE_SIZE / 2)
#define PRIME_INPUT_QUEUE_AHEAD (PRIME_INPUT_QUEUE_SIZE - PRIME_INPUT_QUEUE_BEHIND)
#define PRIME_QUEUE_LIMIT PRIME_INPUT_QUEUE_BEHIND

  // MISH parameters
#define MISH_COORDINATE_INTERVAL (0x80 * 8)

#define INQUEUE(m) ( \
                       ( \
                          ((unsigned short)( \
                                            ((unsigned short)m) - ((unsigned short)(nQHead)) \
                                           ) \
                          ) <= \
                          ((unsigned short) \
                            ( \
                                          ( \
                                            ( \
                                              ( \
                                                (unsigned short)(nQTail) \
                                              ) + (PRIME_QUEUE_SIZE - 1) \
                                            ) % PRIME_QUEUE_SIZE \
                                          ) - ((unsigned short)(nQHead)) \
                            ) \
                          ) \
                       ) && nQSize \
		     )

#define RMINUS(x, y, round_size) ((((unsigned long)x) + round_size - ((unsigned long)y)) % round_size)

#define MOVE_DISTANCE(m1, m2, round_size) (\
                                            (\
                                              ((unsigned long)m2) + round_size - ((unsigned long)m1) \
					    ) % round_size \
					  )

#define INORDER(m1, m, m2, round_size) (MOVE_DISTANCE(m1, m, round_size) <= MOVE_DISTANCE(m, m2, round_size))

#define PRIME_MAX_RETRY 0x1
#define PRIME_BCAST_RETRY 0x1
  // #define PRIME_LISTEN_TIME ((TOS_LOCAL_ADDRESS * 3) % 2 + 1)
#define PRIME_LISTEN_TIME 0
#define PRIME_RECYCLE_TIME 0X90
#define PRIME_REVIVE_TIME 0X300
#define PRIME_PIGGYBACK_WAIT (PRIME_WAIT_TIME / 3)
#define PRIME_CLOCK_DAMP 0x1
  // #define PRIME_GRACE ((unsigned)TOS_LOCAL_ADDRESS % 9)
#define PRIME_GRACE 0
#define PRIME_GOOD_ACTION_GAP 0x8
  // Event queue control
#define PRIME_INSERT_BEFORE 0X1
#define PRIME_INSERT_AFTER 0X2

#define BYTE_OFFSET(X) (((unsigned char)X) >> 3)
#define BIT_OFFSET(X) (((unsigned char)X) & 0x7)

#define RI_MAX_IRECORD 0x10
  typedef struct {
    MacAddress maMaster;
    unsigned long lIteration;
    char cIScore;
  } IRecord;

  typedef struct {
    MacAddress src;
    char queue[PRIME_INPUT_QUEUE_CSIZE];
    char freq;
    char life;
    unsigned char expected;
  } InputQueue;

  typedef struct {
    CellPtr pMsg;
    char confirmed;
    char sent;
    unsigned char to_retry, cNumLink;
  } MsgSendReq;

  typedef long Tick;

  typedef enum {
    PKT_PRIORITY = 0x97,
    PKT_CONTROL = 0x98,
    PKT_DEBUG = 0x99
  } PacketType;

  typedef enum {
    PKT_CONTROL_COORDINATE = 0x1f,
    PKT_CONTROL_REPLY_INVITATION = 0x20,
    PKT_CONTROL_SYNC = 0x21,
    PKT_CONTROL_INVITE_INTERFERENCE = 0x22,
    PKT_CONTROL_WHISPER = 0x23,
    PKT_CONTROL_SHOUT = 0x24
  } ControlPacketType;

  typedef struct {
    // ControlPacketType cptType;
    char cptType;
  } ControlHeader;

  typedef struct {
    ControlHeader chHeader;
    Tick ticTime;
    // /////// int nNumBitSlotInSuperSlot;
    int nNumBitSuperSlotInPeriod;
    Time tNextStart;
  } SyncPacket;

  typedef struct {
    ControlHeader chHeader;
    char cReportNo;
  } WhisperPacket;

  typedef struct {
    ControlHeader chHeader;
    MacAddress maInviter, maShouter, maWhisperer;
    unsigned long lIteration;
    unsigned long lAppointAbsSuperSlot;
  } InviteInterferencePacket;

  typedef struct {
    ControlHeader chHeader;
    MacAddress maInviter, maShouter;
    unsigned long lAppointAbsSuperSlotNo;
  } ReplyInvitationPacket;

  typedef struct {
    ControlHeader chHeader;
    MacAddress maMe, maOther;
    int nMyFirstSuperSlot, nMyLastSuperSlot;
  } CoordinateSuperSlotPacket;

  typedef struct {
    MacAddress maCandidate;
    char cArrived; // whether a report packet arrives
  } TesteeRecord;

  // mode:
#define PRIME_EVT_REPOSTED 0X1

  typedef enum {
    ACTION_COORDINATE = 0x90,
    ACTION_SEND = 0x91,
    ACTION_SHOUT = 0x92,
    ACTION_WHISPER = 0x93,
    ACTION_LISTEN = 0x94,
    ACTION_REPLY_INVITATION = 0x95,
    ACTION_EXAMINE_TEST = 0x96
  } ActionType;

  struct ActionEvent;

  // typedef struct ActionEvent * ActionEventPtr;
  struct ActionEvent {
    unsigned char /* ActionType */ atCode;
    Time tStart, tExpire;
    char mode;
    struct ActionEvent * paeNext;
    union {
      MacAddress maDest;
      unsigned long lNo;
      unsigned int index2msr;
    };
  };

  typedef struct
  {
      struct ActionEvent aePayload;
      char cStatus;
  } AEBlock;

  typedef struct
  {
    MacAddress maID;
  } Neighbor;

  // Data link protocol states.  stDfa is the automaton state.
  enum {
    DL_IDLE = 0,
    DL_DETECT = 1, // detect interfering candidates
    DL_DETECT_SPECIFIC = 2 // detect whether a specific node is an interferer
  } stDfa;

  typedef enum
    {
      YIELD = 0,
      COMPETING = 1,
      COMPETING_SYNC = 2,
      RESERVED,
      INVITE_INTERFERE_ME,
      INVITE_INTERFERE_GROUP,
      DETECT_INTERFERENCE,
    } SlotType;

  typedef struct {
    char filler[4];
    long l1, l2, l3, l4;
  } DebugPacket;

  Tick ticPrime, ticLastStartSym;
  int nMyFirstSuperSlot, nMyLastSuperSlot,
    nSlotNo, nSuperSlotNo,
    nMyFirstSlot, nMyLastSlot;
  unsigned long lAbsSuperSlotNo;

  // These integers must be exponential to 2
  // /////// int nNumSlot, nNumSuperSlot;
  // These are related bits representing the integers above
  int /* //////// nNumBitSlotInSuperSlot,*/ nNumBitSuperSlotInPeriod; 
  Neighbor nbGroup[MAX_GROUP_SIZE];
  MacAddress nbMaster;
  // /////// char cEffectiveSlotTimerRunning;

  char cDlState, gcGeneralState,
    cMacState, cPrev, cPrimeTimerEventPending,
    gcNoPrint;
  int gnGeneralLevel;
  MsgSendReq msrQueue[PRIME_QUEUE_SIZE];
  AEBlock aebPool[PRIME_EVENT_QUEUE_SIZE];

  ///struct ActionEvent aeQueue[PRIME_EVENT_QUEUE_SIZE];
  unsigned int nQHead, nQTail, nQSize;
  unsigned int /* //////// nEqHead, nEqTail, */nEqSize;
  struct ActionEvent *paeHead, *paeTail;
  CellPtr pmsgArrived, pmsgNow, pmsgTXdone, pmsgPriority,
    pmsgAccepted;
  Cell msgControl, msgPriority;

  long lSeq;

  long last_tx_done;
  int nRecycle;
  InputQueue iqGot[PRIME_INPUT_QUEUE_NUM];

  char prev, cLetIn, cUartBusy;
  result_t rRoomy;
  TesteeRecord trCur;

  // debug info
  Cell msgDbg;
  char red_toggle;
  char green_toggle;
  char green_keep;
  char yellow_toggle;
  char dPanic;
  long lKnockThru;
  long dInfo, dPanicInfo;
  long dMe, dPanicMe, dGoodMe, dFuncID, dRemoveEvent, dTransmitTask;
  unsigned long lNumTry, lNumSend, lNumSent, lNumSendFail, 
    lPacketsToSend, lNumMemFreed,
    lNumKnock, lNumRace, dAny;
  IRecord irRI[RI_MAX_IRECORD];
  Tick ticNextStart;
  Tick ticTimeSyncTimer;

  // /////// temporary
  long dTotal;

#define NUM_BIT_IHISTORY 5
#define NUM_HISTORY (1<<NUM_BIT_IHISTORY)
  char cIHistory[NUM_HISTORY], cHardSlot;

  // function prototypes

  void zeroInputQueue();
  void purgeQueue();
  void zeroAEQ();
  struct ActionEvent *staticMalloc(long lSize);
  void staticFree(struct ActionEvent *paeToFree);
  CellPtr processControlPacket(CellPtr pmsgIn);
  CellPtr processNormalPacket(CellPtr pmsgIn);
  void dumpPacket(CellPtr pmsg);
  void zeroIHistory();
  void setIHistory(unsigned long lNo, char cVal);
  result_t sendPacket(char cType,
		      MacAddress maDest, 
		      uint8_t length, 
		      CellPtr data);
  unsigned int enQueue(CellPtr pmsgOut);
  void updateRi(MacAddress maNew, char cIScore, long lIteration);
  void rescheduleHeadEvent(Tick ticNew, Tick ticNewExpire);
  InputQueue *findAllocate(short src);
  void removeEvent();
  result_t addEvent(struct ActionEvent *paeNew);
  void simpleRouter(MacAddress maDest, CellPtr pmsgPacket);
  void bookkeepAfterSent(CellPtr pmsgDone);
  void printPoolInfo();
  void uprint(long lShow);
  void uprint4(long l1, long l2, long l3, long l4);
  result_t syncControl();
  result_t fireEffectiveSlot();
  struct ActionEvent *peekActionEvent();
  void clearIHistory(unsigned long lNo);
  void showLeds(long l);
  result_t checkAQ();

#ifndef nouse
#define DIS_INTERRUPT \
      cPrev = inp(SREG) & 0x80;\
      cli();


#define EN_INTERRUPT \
      if (cPrev)\
	{ \
	  sei(); \
	}

#else
  void inline DIS_INTERRUPT()
    {
    }

  void inline EN_INTERRUPT()
    {
    }
#endif

  // Initialization of this component
  command bool Control.init() {
    int i;
    char *p1, *p2, *p3, cId;

    result_t ok1 = call UARTControl.init();
    result_t ok2 = call RadioControl.init();

    cPrimeTimerEventPending = 0;
    ticPrime = 0;
    // /////// nNumBitSlotInSuperSlot = NUM_BIT_SLOT_IN_SUPERSLOT;
    nNumBitSuperSlotInPeriod = MIN_NUM_BIT_SUPERSLOT_IN_PERIOD;
    lSeq = 1;
    nMyFirstSlot = nMyLastSlot = 0;
    nMyFirstSuperSlot = nMyLastSuperSlot = 
      GetOffset(TOS_LOCAL_ADDRESS, nNumBitSuperSlotInPeriod);
    nSuperSlotNo = nSlotNo = 0;
    lAbsSuperSlotNo = 0;
    nbMaster = -1;
    stDfa = DL_IDLE;
    // cEffectiveSlotTimerRunning = 0;

    nbGroup[0].maID = TOS_LOCAL_ADDRESS;

    for (i=1; i<MAX_GROUP_SIZE; i++)
      {
	nbGroup[i].maID = -1;
      }

    dbg(DBG_AM, "AM init Node ID: %x\n", TOS_LOCAL_ADDRESS);
  
    cDlState = 0;
    gcGeneralState = 0;
    gnGeneralLevel = 0;
    gcNoPrint = 0;
    nQHead = 0;
    nQTail = 0;
    nQSize = 0;
  
    paeHead = paeTail = 0;
    nEqSize = 0;
    rRoomy = SUCCESS;
    pmsgAccepted = 0;

    /* VAR(last_tx_done) = 0; */
    p1 = (char*)&msgDbg;
    p2 = (char*)&msgControl;
    p3 = (char *)&msgPriority;

    for (i = 0; i < sizeof(Cell); i++) {
      p1[i] = 0x51;
      p2[i] = 0x61;
      p3[i] = 0x71;
    }
    
    msgDbg.type = 0x99;
    msgDbg.nSrc = TOS_UART_ADDR;
    msgDbg.group = TOS_AM_GROUP;
    msgDbg.cSeq = 0x12;
    msgDbg.length = AM_MAX_DATA_LENGTH;

    msgControl.type = PKT_CONTROL;
    msgControl.nSrc = TOS_LOCAL_ADDRESS;
    msgControl.group = TOS_AM_GROUP;
    msgControl.cSeq = 0x12;
    msgControl.length = AM_MAX_DATA_LENGTH;

    msgPriority.type = PKT_PRIORITY;
    msgPriority.nSrc = TOS_LOCAL_ADDRESS;
    msgPriority.group = TOS_AM_GROUP;
    msgPriority.cSeq = 0x15;
    msgPriority.addr = TOS_UART_ADDR;
    msgPriority.length = AM_MAX_DATA_LENGTH;

    pmsgArrived = 0;
    pmsgNow = 0;
    pmsgPriority = &msgPriority;

    ticNextStart = GRACE_BEFORE;
    ticTimeSyncTimer = (TIME_SYNC_INTERVAL >> 3) + 
      (TIME_SYNC_INTERVAL >> 2) + 
      (TIME_SYNC_INTERVAL >> 1);
    // VAR(pmsgTXdone) = 0;

    // Initialize input queue
    zeroInputQueue();
    // Initialize interference history
    zeroIHistory();
    zeroAEQ();

    /* the RI need to be dynamic. But the current implementation use 
       static set. A node is not deleted after it's created. */
    for (i=0; i<RI_MAX_IRECORD; i++)
      {
	irRI[i].maMaster = -1;
	irRI[i].lIteration = 0;
	irRI[i].cIScore = 0;
      }

    call Pool.init();

    trCur.maCandidate = TOS_BCAST_ADDR;
    trCur.cArrived = 0;

    cUartBusy = 0;

    // debug
    dPanic = 0;
    lKnockThru = 0;
    dPanicInfo = dPanicMe = 0;
    lNumSend = lNumSendFail = lPacketsToSend = lNumSent = 0;
    lNumMemFreed = lNumTry = lNumKnock = lNumRace = 0;
    dAny = 0;
    dGoodMe = dMe = dFuncID = dRemoveEvent = dTransmitTask = 0;

    dTotal = 0;

    cId = TOS_LOCAL_ADDRESS % PRM_HARD_LENGTH;
    cHardSlot = cId * PRM_HARD_NUM_LINE + 
      (TOS_LOCAL_ADDRESS / PRM_HARD_LENGTH);
    /*(TOS_LOCAL_ADDRESS < PRM_HARD_LENGTH) ? 
       (cId * 2) : (cId * 2 + 1);*/

    dbg(DBG_BOOT, "PRIME Module initialized\n");

    // /////// findAllocate(1-TOS_LOCAL_ADDRESS);
    return rcombine(ok1, ok2);
  } // init

  // Command to be used for power managment
  command bool Control.start() {
    result_t ok1 = call UARTControl.start();
    result_t ok2 = call RadioControl.start();
    result_t ok4 = call PrimeTimer.start(TIMER_REPEAT, TICK_TIME);
    result_t ok3 = SUCCESS;
    // result_t ok3 = call ActivityTimer.start(TIMER_REPEAT, NUM_TICK);

    // unprint(0x66666666);

    dbg(DBG_AM, "SPRIME: start\n");

    return rcombine4(ok1, ok2, ok3, ok4);
  } // start

  
  command bool Control.stop() {
    result_t ok1 = call UARTControl.stop();
    result_t ok2 = call RadioControl.stop();
    result_t ok3 = SUCCESS;
    // result_t ok3 = call ActivityTimer.stop();
    return rcombine3(ok1, ok2, ok3);
  }

  command uint16_t activity() {
    return 0;
  }
  
  void revive()
    {
      int i;

      for (i=0; i<PRIME_INPUT_QUEUE_NUM; i++)
	{
	  iqGot[i].freq = 0;
	} // for i
    } // Revive

  // remove the head item of the queue
  void deHead()
    {
      call Pool.free(msrQueue[nQHead].pMsg);
      nQSize--;
      nQHead = (nQHead + 1) % PRIME_QUEUE_SIZE;

#ifdef DEBUGGING
      // dbg(DBG_AM, "PRIME: DeHead, now qhead %d, qtail %d, qsize %d\n", nQHead, nQTail, nQSize);
      lNumMemFreed++;
#endif
    } // deHead

  // index: index to msrQueue
  // todo: use EDF: deadline is the first priority order, then start time
  result_t insertEvent(unsigned char atCode,
		       Time tStart, 
		       Time tExpire, 
		       char cIndex)
    {
      if (nEqSize < PRIME_EVENT_QUEUE_SIZE)
	{
	  struct ActionEvent *paeNew = 
	    (struct ActionEvent *)(staticMalloc(sizeof(struct ActionEvent)));

	  if (paeNew)
	    {
	      paeNew->tStart = tStart;
	      paeNew->tExpire = tExpire;
	      paeNew->mode = 0;
	      paeNew->index2msr = cIndex;
	      msrQueue[(int)cIndex].cNumLink++;
	      paeNew->atCode = atCode;
	      return addEvent(paeNew);
	    } // if paeNew
	} // if eq not full

      return FAIL;
    } // insertEvent

  // index: index to msrQueue
  result_t postEvent(unsigned char mode, long lTime, char cIndex)
    {
      long dPrevFunc = dFuncID;
      dFuncID = 0x1104;

      return insertEvent(ACTION_SEND, lTime, 0, cIndex);
      dFuncID = dPrevFunc;
    } // postEvent

  void dbgPacket(CellPtr data) {
    uint8_t i;

    for(i = 0; i < sizeof(Cell); i++)
      {
	dbg_clear(DBG_AM, "%02hhx ", ((uint8_t *)data)[i]);
      }
    // dbg(DBG_AM, "\n");
  }

  void staticFree(struct ActionEvent *paeToFree)
    {
      int i;

      for (i=0; i<PRIME_EVENT_QUEUE_SIZE; i++)
	{
	  if ((&(aebPool[i].aePayload)) == paeToFree)
	    {
	      aebPool[i].cStatus = 0;
	      break;
	    }
	} // for
    } // staticFree

  struct ActionEvent *staticMalloc(long lSize)
    {
      int i, nHit = -1;

      for (i=0; i<PRIME_EVENT_QUEUE_SIZE; i++)
	{
	  if (!(aebPool[i].cStatus))
	    {
	      nHit = i;
	      aebPool[i].cStatus = 1;
	      break;
	    }
	} // for

      if (nHit >= 0)
	{
	  return &(aebPool[nHit].aePayload);
	}
      else
	{
	  return 0;
	}
    } // staticMalloc

  // use hard-coded time slices
  SlotType scheduleHardSlot()
    {
      unsigned long lAbsSlotNo = TickToAbsSlotNo(ticPrime);

      ticTimeSyncTimer++;
      if ((lAbsSlotNo % PRM_HARD_ROTATION == cHardSlot) &&
	  (GetOffset(ticPrime, NUM_BIT_TICK_IN_SLOT) < GRACE_STOP_POINT))
	{
	  if (ticTimeSyncTimer > TIME_SYNC_INTERVAL)
	    {
	      ticTimeSyncTimer = 0;
	      uprint(0x12344321);
	      return COMPETING_SYNC;
	    }

	  return COMPETING;
	} // if lAbsSlotNo % PRM_HARD_ROTATION
      else
	{
#ifdef DEBUGGING

	  static char sDamp;

	  KNOCK0;

	  sDamp++;

	  if (/*sDamp & */0x1)
	    {
	      if (paeHead/* || nEqSize || nQSize*/)
		{
		  if (!(paeHead->tStart))
		    {
		      // showLeds(7);
		      // DBG_HALT(0);
		    }

		  if (paeHead->atCode == 0x1c)
		    {
		      showLeds(7);
		      DBG_HALT(0);
		    }

		  /*
		  uprint4
		    ((paeHead->tStart) + (ticPrime<<16), 
		     (paeHead->atCode) + 
		     (((long)
		       (msrQueue[paeHead->index2msr].pMsg->cSeq)) 
		      << 16
		      ),
		     nQSize + (((long)nEqSize) << 16), 
		     (lNumSent << 16) + (paeHead->atCode) + 0x87000000);
		  */
		} // if paeHead
	      else
		{
		  /*uprint4
		    (ticPrime,
		     (long)paeHead,
		     nQSize + (((long)nEqSize) << 16), 
		     (lNumSent << 16) + 0x87000000);*/
		}
	    } // if sDamp
	     
#endif
	  // /////// LEAVE;

	  return YIELD;
	}
    } // scheduleHardSlot()

  /* Slot scheduler
     Priority: detect interference > invite interference > time sync */
  SlotType scheduleSlot()
    {
#define ROTATION_CYCLE 4

      static Tick ticLast;
      static char cRotate;

      SlotType sltR;
      struct ActionEvent *paeFirst;


      
      // If this node needs to shout or whisper, do it.
      paeFirst = peekActionEvent();

      if (paeFirst && 
	  ((paeFirst->atCode == ACTION_SHOUT) ||
	   (paeFirst->atCode == ACTION_WHISPER)))
	{
	  sltR = DETECT_INTERFERENCE;
	}

      // unprint(SYNC_SLOT_NO+0x77000000);
      if ((nSuperSlotNo<nMyFirstSuperSlot) ||
	  (nSuperSlotNo>nMyLastSuperSlot) ||
	  (GetOffset(ticPrime, NUM_BIT_TICK_IN_SLOT) > GRACE_STOP_POINT))
	{
	  // not my super slot
	  // call Leds.yellowOff();

	  sltR = YIELD;

#ifdef DEBUGGINGno
	  if (nSlotNo == 1)
	    {
	      unprint4(dTotal + (lKnockThru<<16), 
		       (((long)nQSize)<<16) + nEqSize, dInfo,
		       0xa6000000+(((unsigned long)cDlState)<<8));
	    }
#endif
	}
      else
	{
	  // call Leds.yellowOn();

	  sltR = COMPETING;

	  switch (nSlotNo)
	    {
	    case DETECT_INTERFERENCE_SLOT_NO:
	      sltR = DETECT_INTERFERENCE;

	      break;

	    case INVITE_INTERFERENCE_SLOT_NO:
	      sltR = COMPETING;
	      
	      switch (cRotate++)
		{
		case 1:
		  // Invite interference
		  // /////// experiment setting: only node 0 invites
		  if (stDfa == DL_IDLE && (!TOS_LOCAL_ADDRESS))
		    {
		      sltR = INVITE_INTERFERE_ME;
		      stDfa = DL_DETECT;
		      trCur.maCandidate = TOS_BCAST_ADDR;
		      zeroIHistory();
		    } // if
		  
		  break;

		default:
		  // unprint(SYNC_SLOT_NO+0x77000000);
		  break;
		} // switch

	      if (cRotate == ROTATION_CYCLE)
		{
		  cRotate = 0;
		} // cRotate == ROTATION_CYCLE

	      break;

	    case SYNC_SLOT_NO:
	      // /////// time sync temporarily passed
	      sltR = ((ticPrime - ticLast > TIME_SYNC_INTERVAL) &&
		      cRotate == (TOS_LOCAL_ADDRESS % ROTATION_CYCLE)) ?
		((ticLast = ticPrime), COMPETING_SYNC) : 
		COMPETING;

	      break;

	    default:
	      sltR = COMPETING;
	      // break;
	    } // switch (nSlotNo)
	} // else active super slot

      // dbg(DBG_AM, "PRIME:scheduleSlot@%lx: %d->%d\n", ticPrime, nSlotNo, sltR);
      // unprint4(ticPrime, sltR, nSlotNo, 0x76000000+nSuperSlotNo);

      dbg(DBG_AM,
	  "PRM$scheduleSlot@%lx: ticLast %lx, cRotate %d interval %x => %d\n",
	  ticPrime, ticLast, cRotate, TIME_SYNC_INTERVAL, sltR);

      return sltR;
    } // scheduleSlot

  /* Find an owned superslot for interference detection. The
     invitation may need to be forwarded ahead the current
     iterating sequence number is included */
  unsigned long appointAbsSuperSlot()
    {
      return ((GET_PERIOD_NO(ticPrime) + GETj(lSeq) + 1) <<
	      nNumBitSuperSlotInPeriod) + nMyFirstSuperSlot;
    } // appointAbsSuperSlot

  void evacuate(int i)
    {
      InputQueue *piqCur = &(iqGot[i]);
      int j;

      piqCur->src = -1;
      piqCur->expected = 0;
      piqCur->freq = 0;
      piqCur->life = 0;

      for (j=0; j<PRIME_INPUT_QUEUE_CSIZE; j++)
	{
	  piqCur->queue[j] = 0;
	} // for j
    } // Evacuate

  void zeroInputQueue()
    {
      int i;

      for (i=0; i<PRIME_INPUT_QUEUE_NUM; i++)
	{
	  evacuate(i);
	} // for i
    } // zeroInputQueue

  // Handle the event of the completion of a message transmission
  result_t reportSendDone(CellPtr msg, result_t success) {
    signal SendMsg.sendDone[msg->type](((TOS_MsgPtr)msg), success);
    signal sendDone();

    return SUCCESS;
  }

  char IsCompeting()
    {
      return 1;
    }

  // needs to be sync protected outside ///////
  void purgeQueue()
    {
      while(nQSize)
	{
	  MsgSendReq *pmsrHead = &(msrQueue[nQHead]);

	  // if (pmsrHead->confirmed && pmsrHead->sent)
	  if (!(pmsrHead->cNumLink))
	    {
	      call Pool.free(msrQueue[nQHead].pMsg);
	      lNumMemFreed++;
	      nQSize--;
	      nQHead = (nQHead + 1) % PRIME_QUEUE_SIZE;
	    }
	  else
	    break;
	}

      dbg(DBG_AM, 
	  "PRIME:purgeQueue@%lx: end q: %d/%d/%d\n",
	  ticPrime, nQHead, nQTail, nQSize);
    } // purgeQueue

  /* Reschedule the first event in the action event queue
     to another time.
     If ticNewExpire == ticNew: adjust the expire time to maintain
     the same event valid period.
     Otherwise, set the expire time to the ticNewExpire. */
  void rescheduleHeadEvent(Tick ticNew, Tick ticNewExpire)
    {
      // need to protect it outside
      
      struct ActionEvent *paeOldHead = paeHead;
      dFuncID = 0x21;

      DBG_HALT(7);

      if (!paeHead)
	{
	  dPanic = 1;
	  dbg(DBG_AM, "PRIME: !!!!!!!!!very strange\n");

	  return;
	} 

      paeHead->tExpire = (ticNew == ticNewExpire) ?
	((paeHead->tExpire) ?
	 (paeHead->tExpire + ticNew - paeHead->tStart) : 0) :
	ticNewExpire;
      paeHead->tStart = ticNew;
      paeHead = paeHead->paeNext;
      paeTail = paeHead ? paeTail : 0;
      nEqSize--;
      addEvent(paeOldHead);

      dbg(DBG_AM, 
	  "PRIME: rescheduleEvent@%lx: Event Queue Head %p Tail %p Size %x\n",
	  ticPrime, paeHead,paeTail,nEqSize);
    } // rescheduleHeadEvent

  task void sendTask() {
    result_t ok;

    CellPtr pmsgToSend;

    // Event queue must be non-empty
    if (!(nEqSize))
      {
	dbg(DBG_AM, 
	    "PRIME:? sendTask: zero eqsize : eqhead, eqsize: %p, %x \n", 
	    paeHead, nEqSize);

	return;
      }


    VOID_KNOCK(0x1101);

    lNumSend++;

    KNOCKREC(0xaaaa);
  
    if (paeHead->tExpire && paeHead->tExpire < ticPrime)
      {

	removeEvent();

	LEAVE;

	return;
      }
    else
      {
	paeHead->tExpire = ticPrime - 1;
      }

    // ///////LEAVE;

    // call Leds.yellowToggle();
    // unprint4(ticPrime, ~cDlState, nEqSize, 0x11000000+(((unsigned long)cDlState)<<8)+ ((unsigned long)(paeHead->atCode)));

    pmsgToSend = msrQueue[paeHead->index2msr].pMsg;

#ifdef DEBUGING

    dbg(DBG_AM, 
	"AM send task: msg: %p, eqsize 0x%x, 0x%x\n", 
	pmsgToSend, nEqSize);
#endif

    if(pmsgToSend->addr == TOS_UART_ADDR){
      if((ok = call UARTSend.send((TOS_MsgPtr)pmsgToSend)) != SUCCESS){
	//TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(msg));
	// dbg(DBG_AM, ("MAC_BUSY ERROR\n"));

	LEAVE;

	return;
      }
    } // if uart addr
    else
      {
	nRecycle = 0;

#ifdef DBG_DUMP_MSG
	dumpPacket(pmsgToSend);
#endif

	// unprint4(ticPrime, nEqSize, nQSize, 0x81000000+(((unsigned long)cDlState)<<8)+ ((unsigned long)(paeHead->atCode)));
	if((ok = call RadioSend.send((TOS_MsgPtr)pmsgToSend)) != SUCCESS){
	  cDlState |= PRIME_LOWER_ERROR;
	  // paeHead->mode &= (~(PRIME_EVT_REPOSTED));

	  LEAVE;

	  return;
	}
	else 
	  {
	    // should removeEvent(), but cannot do it without lock

	    KNOCKREC(0xaa55);

	    removeEvent();
	    // uprint4(ticPrime, pmsgToSend->type, nEqSize + (((long)nQSize) << 16), 0x18000000+(((unsigned long)cDlState)<<8)+ ((unsigned long)(paeHead->atCode)));

	    // /////// LEAVE;
	    // unprint4(ticPrime, 0, 0, 0x88888888);
	  }
      } // else uart addr

    if (ok == FAIL) // failed, signal completion immediately
      reportSendDone(pmsgToSend, FAIL);

    LEAVE;

    return;
  } // sendTask

  // Send a packet without CSMA
  task void sendNow() {
    result_t ok;
    
    showLeds(7);
    DBG_HALT(0);

    lNumSend++;

    // unprint4(ticPrime, dInfo, dMe, 
    //    0x98000000+(((long)(~cDlState))<<8)+((char *)pmsgNow)[8]);

    dbg(DBG_AM, "PRIME sendNow: tick %lx msg: %p\n", ticPrime, pmsgNow);
    
#ifdef DBG_DUMP_MSG
    dumpPacket(pmsgNow);
#endif

    // unprint(SYNC_SLOT_NO+0x95000000);

    if(pmsgNow->addr == TOS_UART_ADDR){
      if((ok = call UARTSend.send((TOS_MsgPtr)pmsgNow)) != SUCCESS){
	//TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(msg));
	dbg(DBG_AM, "PRIME: UART ERROR\n");

	return;
      }
    } // if uart addr
    else
      {
	SyncPacket *pspktTime = (SyncPacket *)(pmsgNow->data);

	nRecycle = 0;

	if ((pspktTime->chHeader).cptType == PKT_CONTROL_SYNC)
	  {
	    // unprint(SYNC_SLOT_NO+0x99000000);
	    pspktTime->ticTime = ticPrime;
	    pspktTime->tNextStart = ticNextStart + SLOT_TICK;
	  }

	// unprint(SYNC_SLOT_NO+0x97000000);
	ok = call RadioSend.sendNow((TOS_MsgPtr)pmsgNow);
	if(ok != SUCCESS){
	  // uprint(SYNC_SLOT_NO+0xdededede);
	  cDlState |= PRIME_LOWER_ERROR;
	  // paeHead->mode &= (~(PRIME_EVT_REPOSTED));
	  dbg(DBG_AM, "PRIME: error sendNow %lx\n", ticPrime);
	  reportSendDone(pmsgNow, FAIL);
	} // if sub_tx
      } // else uart addr
    // call Leds.yellowToggle();
    // unprint(SYNC_SLOT_NO+0x92000000);
  } // sendNow

  // Send a packet with CSMA
  task void sendCSMA() {
    result_t ok;

    VOID_KNOCK(0x7707);

    lNumSend++;

    // unprint4(ticPrime, dInfo, dMe, 
    //    0x98000000+(((long)(~cDlState))<<8)+((char *)pmsgNow)[8]);

    dbg(DBG_AM, "PRIME sendNow: tick %lx msg: %p\n", ticPrime, pmsgNow);
    
#ifdef DBG_DUMP_MSG
    dumpPacket(pmsgNow);
#endif

    // unprint(SYNC_SLOT_NO+0x95000000);

    if(pmsgNow->addr == TOS_UART_ADDR){
      if((ok = call UARTSend.send((TOS_MsgPtr)pmsgNow)) != SUCCESS){
	//TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(msg));
	dbg(DBG_AM, "PRIME: UART ERROR\n");

	LEAVE;

	return;
      }
    } // if uart addr
    else
      {
	SyncPacket *pspktTime = (SyncPacket *)(pmsgNow->data);

	nRecycle = 0;

	if ((pspktTime->chHeader).cptType == PKT_CONTROL_SYNC)
	  {
	    // unprint(SYNC_SLOT_NO+0x99000000);
	    pspktTime->ticTime = ticPrime;
	    pspktTime->tNextStart = ticNextStart + SLOT_TICK;
	  }

	// unprint(SYNC_SLOT_NO+0x97000000);
	ok = call RadioSend.send((TOS_MsgPtr)pmsgNow);
	if(ok != SUCCESS){
	  // unprint(SYNC_SLOT_NO+0xdededede);
	  cDlState |= PRIME_LOWER_ERROR;
	  // paeHead->mode &= (~(PRIME_EVT_REPOSTED));
	  dbg(DBG_AM, "PRIME: error sendNow %lx\n", ticPrime);
	  reportSendDone(pmsgNow, FAIL);
	} // if sub_tx
      } // else uart addr
    // call Leds.yellowToggle();
    // unprint(SYNC_SLOT_NO+0x92000000);

    LEAVE;

    return;
  } // sendCSMA

  void sendPriorityUART() {
    result_t ok;

    if (cUartBusy)
      {
	return;
      }

    if((ok = call UARTSend.send((TOS_MsgPtr)pmsgPriority)) != SUCCESS){
      //TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(msg));
      return;
    }
    else
      {
	cUartBusy = 1;
      }
  } // sendPriorityUART

  void sendPriorityUARTPkt(Cell *pcell) {
    result_t ok;

    if (cUartBusy)
      return;

    if((ok = call UARTSend.send((TOS_MsgPtr)pcell)) != SUCCESS){
      //TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(msg));
      return;
    }
    else
      {
	cUartBusy = 1;
      }
  } // sendPriorityUARTPkt

  void sendPriority() {
    result_t ok;

    if(((MacAddress)(pmsgPriority->addr)) == ((MacAddress)TOS_UART_ADDR)){
      lNumSend++;

      if((ok = call UARTSend.send((TOS_MsgPtr)pmsgPriority)) != SUCCESS){
	//TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE)(VAR(msg));
	return;
      }
    } // if uart addr
    else
      {
	lNumSend++;

	nRecycle = 0;

	ok = call RadioSend.send((TOS_MsgPtr)pmsgPriority);
	if(ok != SUCCESS){
	  cDlState |= PRIME_LOWER_ERROR;
	  // paeHead->mode &= (~(PRIME_EVT_REPOSTED));
	  dbg(DBG_AM, "PRIME: error priority %lx\n", ticPrime);
	  reportSendDone(pmsgPriority, FAIL);
	} // if sub_tx
      } // else uart addr
  } // sendPriority

  event result_t ActivityTimer.fired() {
    return SUCCESS;
  }
  
  event result_t PrimeTimer.fired() {
    result_t ok = SUCCESS;

    ticPrime++;

    if (nEqSize >= 4 && (((struct ActionEvent *)(0x0365))->paeNext != 
			 ((struct ActionEvent *)0x0376)))
      {
	// showLeds(dGoodMe);
	uprint4(ticPrime, dGoodMe, dFuncID, 0x55660000 + checkAQ() + 2);
	gcNoPrint = 1;
      }
    
    KNOCK(FAIL, 0x7708);

    /*    if ((ticPrime & PRIME_CLOCK_DAMP) && !(cLetIn))
	  return SUCCESS; */

    /* After synchronizing the clock, the effective slot timer
       needs to restart */
    if (/*(!cEffectiveSlotTimerRunning) && (*/ticPrime >= ticNextStart/*)*/)
      {
	dbg(DBG_AM, 
	    "EffectiveSlotTimer started at tick 0x%lx, interval: 0x%x\n", 
	    ticPrime, SLOT_TIME);

	// ticNextStart = (ticNextStart & TICK_IN_SLOT_UNMASK) + 
	// SLOT_TICK + GRACE_BEFORE;
	ticNextStart += SLOT_TICK;
	// cEffectiveSlotTimerRunning = 1;
	// ok = call EffectiveSlotTimer.start(TIMER_REPEAT, SLOT_TIME);
	fireEffectiveSlot();
      }

    /* ///////    if (!(ticPrime % PRIME_REVIVE_TIME))
       revive(); */

    // debug: need to remove for release
    // DebugControl();

#ifdef nouse
    if ((ticPrime & 0xff) == 1)
      {
	uprint4(ticPrime, dMe, dInfo, 0x39000000+cDlState);
      }
#endif

#ifdef USE_LED
    if ((ticPrime & 0x100) && (ticPrime < 0x800))
      {
	TOSH_CLR_GREEN_LED_PIN();
      }
    else
      {
	/*	if (!(ticPrime & 0x1ff))
		{
		unprint4(ticPrime, nEqSize, nQSize, 0x55550000);
		}*/
	TOSH_SET_GREEN_LED_PIN();
      }

#endif
    LEAVE;

    return ok;
  } // PrimeTimer.fired

  void dumpActionQueue()
    {
      struct ActionEvent *paeNow = paeHead;
      int nTotal = 0;

      dbg(DBG_AM, "PRIME:ActionEvent Queue s-%d:\n", nEqSize);
      printPoolInfo();

      while (paeNow)
	{
	  dbg(DBG_AM, "\t%p->%p: action %x @%lx/%lx", 
	      paeNow, paeNow->paeNext, paeNow->atCode, 
	      paeNow->tStart, paeNow->tExpire);

	  nTotal++;

	  switch (paeNow->atCode)
	    {
	    case ACTION_SEND:
	      dbg_clear(DBG_AM, " --- to_retry: %d", 
			msrQueue[paeNow->index2msr].to_retry);
	      break;
	    default:
	      break;
	    }

	  dbg_clear(DBG_AM, "\n");

	  paeNow=paeNow->paeNext;
	}

      if (nTotal != nEqSize)
	{
	  dbg(DBG_AM, "PRIME:dumpActionQueue@%lx: size error\n", ticPrime);
	}
    } // dumpActionQueue

  void printPoolInfo()
    {
      PoolInfo *ppiPool = call Pool.getInfo();
      dbg(DBG_AM, "PRIME:printPoolInfo@%lx: q %d, eq %d, pool %d/%ld/%ld\n",
	  ticPrime, nQSize, nEqSize, ppiPool->nOccupied,
	  ppiPool->lNumAlloc, ppiPool->lNumFree);
      return;
    } // printPoolInfo

  // needs to be sync protected outside ///////
  void queueKeeping()
    {
      char cEventRemoved = 0;
      
      dFuncID = 0x1103;

#ifdef DBG_DUMP_MSG
      dbg(DBG_AM, "PRIME:queueKeeping@%lx before\n", ticPrime);
      printPoolInfo();
#endif
      while (paeHead && ((paeHead->tExpire && paeHead->tExpire<ticPrime) ||
			 // Finished outgoing packets
			 ((paeHead->atCode == ((unsigned char)ACTION_SEND)) &&
			  !(msrQueue[paeHead->index2msr].to_retry))))
	{
	  removeEvent();
	  cEventRemoved = 1;
	} // while

      purgeQueue();

#ifdef DBG_DUMP_MSG
      dbg(DBG_AM, "PRIME:queueKeeping@%lx after\n", ticPrime);
      printPoolInfo();
#endif
    } // queueKeeping

  /* Transmit the first packet as described by the head event.
     The event must be of kind ACTION_SEND */

  task void transmitTask()
    {
      MsgSendReq *pmsrCur;
      
      dbg(DBG_AM, "PRIME:transmitTask@%lx\n", ticPrime);
      dFuncID = 0x1102;

      VOID_KNOCK(0x1102); // prev 4

      dTransmitTask++;

      // uprint4(gnGeneralLevel, nEqSize, dGoodMe + (dMe << 16), 0x33550000);

#ifdef DEBUGGING
      if ((nQHead + nQSize) % PRIME_QUEUE_SIZE != nQTail)
	{
	  showLeds(7);
	  DBG_HALT(0);
	}

      /*      if ((nEqHead + nEqSize) % PRIME_EVENT_QUEUE_SIZE != nEqTail)
	{
	  showLeds(3);
	  DBG_HALT(0);
	  dbg(DBG_AM, "PRIME: panic queue eqhead %d, eqtail %d, eqsize %d\n", nEqHead, nEqTail, nEqSize);
	}
      */
#endif

      if (nEqSize && (paeHead->atCode == ((unsigned char)ACTION_SEND)))
	{
	  // try to remove an unnecessry event
	  pmsrCur = &(msrQueue[paeHead->index2msr]);

	  dbg(DBG_AM, 
	      "PRIME:transmitTask@%#lx: pmsrCur %p. paeHead %p, index2msr %x\n", 
	      ticPrime, pmsrCur, paeHead, paeHead->index2msr);
	} // if eqsize
      else
	{

	  LEAVE;

	  return;
	}

      if (paeHead->tExpire && ticPrime > paeHead->tExpire)
	{
	  // Event has expired
	  pmsrCur->to_retry = 0;
	  paeHead->mode &= (~(PRIME_EVT_REPOSTED));
	}

      if ((!(paeHead->mode & PRIME_EVT_REPOSTED)) &&
	  (!(paeHead->tExpire) || ticPrime <= paeHead->tExpire))
	{
	  if(cMacState == 0)
	    {
	      if (pmsrCur->to_retry)
		{
		  // retry sending
		  dbg(DBG_AM, 
		      "PRIME:transmitTask@%#lx:sending, qhead %x,qsize %x\n",
		      ticPrime, nQHead, nQSize);

		  // unprint4(ticPrime, nEqSize, nQSize, 0x19000000+(((unsigned long)cDlState)<<8)+ ((unsigned long)(paeHead->atCode)));

		  pmsrCur->to_retry--;

		  // /////// confirmation logic needs to be repaired
		  if ((postEvent(PRIME_INSERT_AFTER, 
				 ticPrime+PRIME_WAIT_TIME, paeHead->index2msr)) 
		      == SUCCESS)
		    {
		      // success
		      post sendTask();
		      paeHead->mode |= PRIME_EVT_REPOSTED;
		      pmsrCur->to_retry = 0;
		      lNumTry++;
		    }
		  else // else postEvent ok
		    {
		      // Event is unable to be posted. Have to be ready
		      // to give up the packet. Otherwise this packet may
		      // never be removed.

		      pmsrCur->to_retry = 0;	
		    } // else postEvent ok
		}
	      else // pmsrCur->to_retry
		{
		  /* stop sending (out of retry number, but not necessary 
		     failure.) The confirmed and sent tags need still to
		     be set because the msr may be in the middle of the
		     queue so as not to be purged out now. */
		  dbg(DBG_AM, 
		      "PRIME:stop sending: index2msr %d, q:%d/%d/%d, confirm %d, sent %d, addr %p, pmsrCur %p\n", 
		      paeHead->index2msr, nQHead, nQTail, nQSize, 
		      msrQueue[nQHead].confirmed, msrQueue[nQHead].sent, 
		      &(msrQueue[nQHead]), pmsrCur);
		  pmsrCur->confirmed = 1;
		  pmsrCur->sent = 8;
		  lNumSendFail++; // but not necessarily failure. re-calc
		  reportSendDone(pmsrCur->pMsg, FAIL);
		  paeHead->tExpire = ticPrime - 1;
		  queueKeeping();

		  // /////// debug
#ifdef DEBUGGING
		  // call AM_DBG_SEND3("S", pmsrCur->pMsg->addr, (((long)nEqSize)<<16) + ticPrime /* paeHead->index2msr*/);
		  // dbg(DBG_AM, ("PRIME: give up retrying: index2msr %d, qsize: %d, head %d confirm %d, sent %d, addr %p, pmsrCur %p, qtail %d\n", paeHead->index2msr, nQSize, nQHead, msrQueue[nQHead].confirmed, msrQueue[nQHead].sent, &(msrQueue[nQHead]), pmsrCur, nQTail));
#endif	
		} // if to_retry
	    } // if Macstate == 0
	  else
	    {
	      dbg(DBG_AM, "PRIME:transmitTask@%lx: MAC state non-zero\n",
		  ticPrime);
	    } // else MacState == 0
	} // if tick - time >= 0

      LEAVE;

      // uprint4(gnGeneralLevel, nEqSize, dGoodMe + (dMe << 16), 0x33660000);

      return;
    } // transmitTask

  result_t transmitPacket() {
    post transmitTask();
    return SUCCESS;
  }

  result_t sendCoordinateControlPacket(MacAddress maOther)
    {
      if (nEqSize < PRIME_EVENT_QUEUE_SIZE)
	{
	  CellPtr pmsgCoordinate = call Pool.copy(&msgControl);
	  CoordinateSuperSlotPacket *pcsspNew;

	  if (!pmsgCoordinate) 
	    {return FAIL;}
	  
	  dbg(DBG_AM, "PRIME:coordinateSuperSlot@%lx\n", ticPrime);

	  pcsspNew = (CoordinateSuperSlotPacket *)(pmsgCoordinate->data);
	  pmsgCoordinate->type = PKT_CONTROL;
	  (pcsspNew->chHeader).cptType = PKT_CONTROL_COORDINATE;
	  pcsspNew->maMe = TOS_LOCAL_ADDRESS;
	  pcsspNew->maOther = maOther;
	  pcsspNew->nMyFirstSuperSlot = nMyFirstSuperSlot;
	  pcsspNew->nMyLastSuperSlot = nMyLastSuperSlot;

	  simpleRouter(maOther, pmsgCoordinate);

	  return SUCCESS;
	} // if eq not full
      else
	{
	  return FAIL;
	}
    } // sendCoordinateControlPacket

  /* Coordinate the usage of super slots with another node.
     Send a message to the other node to tell it this node's
     usage of super slots in a period. When there is a conflict,
     the node with higher MacAddress changes its schedule. This
     coordination needs to be done periodically.
     An ACTION_COORDINATE event is posted. This is a periodic
     event.
     The coordinate control packet will be sent when processing
     the ACTION_COORDINATE event. */
  // todo: the yield logic need to consider the cost. using MacAddress to arbitrate may not be good enough.
  result_t coordinateSuperSlot(MacAddress maOther)
    {
      // ///////      unsigned int nQPos;
      struct ActionEvent *paeNew = 
	(struct ActionEvent *)(staticMalloc(sizeof(struct ActionEvent)));

      showLeds(7);
      DBG_HALT(0);

      if (!paeNew)
	{return FAIL;}
      
      /* Post the coordinate action. */
      paeNew->tStart = paeTail ?
	paeTail->tStart + PRIME_GOOD_ACTION_GAP :
	ticPrime;
      paeNew->tExpire = 0;
      paeNew->mode = 0;
      paeNew->atCode = ACTION_COORDINATE;
      paeNew->maDest = maOther;

      return addEvent(paeNew);
    } // coordinateSuperSlot

  /* Update the record of maNew in RI with cIScore. If the record
     does not exist, create it. maNew mut not be TOS_BCASE_ADDR.
     All valid RI records has a non-zero lIteration value. If the
     lIteration is -1, the number of maximum hops to the node
     is unknown.

     When the cIScore is negative, the node is not in RI. When
     it's positive, the node's in RI. When it's zero, the node is
     an RI candidate. 
     
     If the parameter cIScore is added to the cIScore in the record. If
     the node is still not in RI, the cIScore in the record for this new 
     node is set to the parameter cIScore. Therefore, calling this
     function with a cIScore parameter of 0 will add an interfering
     candidate if it has not been there. */
  // todo: hash table may be better
  void updateRi(MacAddress maNew, char cIScore, long lIteration)
    {
      int i;
      IRecord * pirNew = 0;

      for (i=0; i<RI_MAX_IRECORD; i++)
	{
	  if (irRI[i].lIteration)
	    {
	      // valid record
	      if (irRI[i].maMaster == maNew)
		{
		  // located the record
		  pirNew = &(irRI[i]);
		  break;
		} // if irRI[i].maMaster == maNew
	    } // if irRI[i].lIteration
	  else
	    {
	      /* invalid record. Replace it with a valid record
		 for maNew. Since a new record is created, the
	         coordination of superslot usage is needed if the
	         cIScore is larger than zero. */
	      pirNew = &(irRI[i]);
	      pirNew->maMaster = maNew;
	      pirNew->lIteration = lIteration;
	      pirNew->cIScore = 0;
	      break;
	    } // else irRI[i].lIteration
	} // for

      if (pirNew)
	{
	  pirNew->cIScore += cIScore;

	  if (pirNew->cIScore >= PRM_MAX_ISCORE)
	    {
	      pirNew->cIScore = PRM_MAX_ISCORE;
	    } // if pirNew->cIScore
	  else
	    {
	      if (pirNew->cIScore <= -PRM_MAX_ISCORE)
		{
		  pirNew->cIScore = -PRM_MAX_ISCORE;
		} // if
	    } // else pirNew->cIScore

	  if ((pirNew->cIScore > 0) && (maNew > TOS_LOCAL_ADDRESS))
	    {
	      coordinateSuperSlot(maNew);
	    } // if (!cIScore)
	} // if pirNew
      else
	{
	  // irRI full
	  dbg(DBG_AM, "PRIME: irRI full\n");
	} // else pirNew
    } // updateRi

  /* Examine RI to find the next candidate */
  MacAddress selectCandidate()
    {
      int i;

      for (i=0; i<RI_MAX_IRECORD; i++)
	{
	  if ((irRI[i].lIteration) && 
	      (!(irRI[i].cIScore)))
	    {
	      // candidate found
	      return irRI[i].maMaster;
	    } // if irRI[i].lIteration
	} // for

      return TOS_BCAST_ADDR;
    } // selectCandidate

  /* Find another node to help detect the interference
     The whisperer must be in RI-set */
  // Todo: should be the weakest neighbor
  MacAddress findWhisperer()
    {
      if (iqGot[0].src == (MacAddress)TOS_BCAST_ADDR)
	{
	  return TOS_BCAST_ADDR;
	}
      else
	{
	  updateRi(iqGot[0].src, (PRM_MAX_ISCORE << 1), 1);
	  return (MacAddress)(iqGot[0].src);
	} // else iqGot[0].src
    } // findWhisperer

  result_t syncControl() {
    SyncPacket *pspktTime;

    dbg(DBG_AM, "PRIME: syncControl tick:%lx\n", ticPrime);

    pmsgNow = &msgControl;
    pmsgNow->addr = TOS_BCAST_ADDR;
    pspktTime = (SyncPacket *)(pmsgNow->data);
    (pspktTime->chHeader).cptType = PKT_CONTROL_SYNC;
    // unprint(0x12345678);
    post sendCSMA();

    return SUCCESS;
  } // syncControl

  result_t postListenEvent(unsigned long lAbsSuperSlot)
    {
      showLeds(0);
      DBG_HALT(0);
      if (nEqSize < PRIME_EVENT_QUEUE_SIZE)
	{
	  struct ActionEvent *paeNew = 
	    (struct ActionEvent *)(staticMalloc(sizeof(struct ActionEvent)));

	  paeNew->tStart = AbsSuperSlotToTick(lAbsSuperSlot) +
	    SlotToNumTick(DETECT_INTERFERENCE_SLOT_NO);
	  paeNew->tExpire = (paeNew->tStart) + SlotToNumTick(1) - 1;
	  paeNew->mode = 0;
	  paeNew->atCode = ACTION_LISTEN;

	  addEvent(paeNew);

	  return SUCCESS;
	} // if eq not full
      else
	{
	  return FAIL;
	}
    }

  result_t inviteInterference() {
    InviteInterferencePacket *piipInvite;
    MacAddress maWhisperer = findWhisperer();

    dbg(DBG_AM, "PRIME: invite Interfernece tick:%lx\n", ticPrime);

    if (maWhisperer == TOS_BCAST_ADDR)
      {
	stDfa = DL_IDLE;
	return FAIL;
      }

    pmsgNow = &msgControl;
    pmsgNow->addr = TOS_BCAST_ADDR;
    piipInvite = (InviteInterferencePacket *)(pmsgNow->data);
    (piipInvite->chHeader).cptType = PKT_CONTROL_INVITE_INTERFERENCE;
    piipInvite->maInviter = TOS_LOCAL_ADDRESS;
    piipInvite->maWhisperer = maWhisperer;
    piipInvite->maShouter = TOS_BCAST_ADDR;
    piipInvite->lAppointAbsSuperSlot = appointAbsSuperSlot();
    piipInvite->lIteration = GETj(lSeq);
    postListenEvent(piipInvite->lAppointAbsSuperSlot);

    post sendCSMA();

    dbg(DBG_AM, "PRIME: whisperer %x, seq/iterating seq: %ld/%ld\n", 
	maWhisperer, lSeq, GETj(lSeq));

    return SUCCESS;
  } // syncInvitation

#define NUM_WHISPER 0x3
  result_t shout()
    {
      WhisperPacket *pwpktWhisper;

      dbg(DBG_AM, "PRIME: shout tick:%lx\n", ticPrime);

      pmsgNow = &msgControl;
      pwpktWhisper = (WhisperPacket *)(pmsgNow->data);
      (pwpktWhisper->chHeader).cptType = PKT_CONTROL_SHOUT;
      pwpktWhisper->cReportNo = NUM_WHISPER;

      post sendNow();
      
      return SUCCESS;
    } // shout

  result_t whisper(MacAddress maDest)
    {
      WhisperPacket *pwpktWhisper;

      dbg(DBG_AM, "PRIME: whisper tick:%lx\n", ticPrime);

      pmsgNow = &msgControl;
      pmsgNow->addr = maDest;
      pwpktWhisper = (WhisperPacket *)(pmsgNow->data);
      (pwpktWhisper->chHeader).cptType = PKT_CONTROL_WHISPER;
      pwpktWhisper->cReportNo = NUM_WHISPER;

      post sendNow();
      
      return SUCCESS;
    } //whisper

  result_t continueSend()
    {
      WhisperPacket *pwpktWhisper;


      pwpktWhisper = (WhisperPacket *)(pmsgNow->data);
      if (--(pwpktWhisper->cReportNo))
	{
	  dbg(DBG_AM, "PRIME: continueSend tick:%lx\n", ticPrime);
	  post sendNow();
	}

      
      return SUCCESS;
    } //continueSend

  result_t listenReport()
    {
      struct ActionEvent *paeNew;

      showLeds(0);
      DBG_HALT(0);

      dbg(DBG_AM, "PRIME:listenReport@%lx\n", ticPrime);

      setIHistory(lAbsSuperSlotNo, NUM_WHISPER);

      // Set a time to examine the result of the test
      paeNew = (struct ActionEvent *)(staticMalloc(sizeof(struct ActionEvent)));

      if (paeNew && (nEqSize < PRIME_EVENT_QUEUE_SIZE))
	{
	  paeNew->tStart = ticPrime + PRM_TEST_LENGTH;
	  paeNew->tExpire = 0;
	  paeNew->mode = 0;
	  paeNew->atCode = ACTION_EXAMINE_TEST;
	  paeNew->lNo = lAbsSuperSlotNo;

	  addEvent(paeNew);
	} // if paeNew eq not full
      else
	{
	  return FAIL;
	}

      return SUCCESS;
    } // listenReport
  
  // Return the first effective action event
  // needs to be sync protected outside ///////
  struct ActionEvent *peekActionEvent()
    {
      if (paeHead && paeHead->tStart<=ticPrime)
	{
	  return paeHead;
	}
      else
	{return 0;}
    } // peekActionEvent

  void zeroAEQ()
    {
      int i;
      
      for (i=0; i<PRIME_EVENT_QUEUE_SIZE; i++)
	{
	  aebPool[i].cStatus = 0;
	} // for

      return;
    } // zeroAEQ

  void clearIHistory(unsigned long lNo)
    {
      cIHistory[lNo & NUM_BIT_IHISTORY] = 0;
    } // clearIHistory

  void decreaseIHistory(unsigned long lNo)
    {
      cIHistory[lNo & NUM_BIT_IHISTORY]--;
    } // decreaseIHistory

  char isCleanIHistory(unsigned long lNo)
    {
      return !(cIHistory[lNo & NUM_BIT_IHISTORY]);
    } // isCleanIHistory

  void setIHistory(unsigned long lNo, char cVal)
    {
      cIHistory[lNo & NUM_BIT_IHISTORY] = cVal;
    } // setIHistory

  void zeroIHistory()
    {
      int i;

      for (i=0; i<NUM_HISTORY; i++)
	{
	  cIHistory[i] = 0;
	}
    } // zeroHistory

  /* Reply to an inviter to let the latter know this node has
     shouted at a specific superslot. */
  result_t replyInvitation(MacAddress maInviter, unsigned long lSuperSlot)
    {
      CellPtr pmsgReply = call Pool.copy((CellPtr)(&msgControl));
      ReplyInvitationPacket *pripReply;
      
      if (!pmsgReply)
	{return FAIL;}
      
      dbg(DBG_AM, "PRM$replyInvitation@%lx\n", ticPrime);
      pripReply = (ReplyInvitationPacket *)(pmsgReply->data);
      (pripReply->chHeader).cptType = PKT_CONTROL_REPLY_INVITATION;
      pripReply->maInviter = maInviter;
      pripReply->maShouter = TOS_LOCAL_ADDRESS;
      pripReply->lAppointAbsSuperSlotNo = lSuperSlot;
      sendPacket(PKT_CONTROL, maInviter, DATA_LENGTH-8, pmsgReply);

#ifdef DEBUGGING
      /* unprint4(ticPrime, maInviter+0xabababab,
	      (((long)nQSize)<<16) + nEqSize,
	      0xb7000000+(((unsigned long)cDlState)<<8));*/
#endif

      return SUCCESS;
    } // replyInvitation

  /* Need to shout and return a reply to the inviter. */
  result_t doShout(struct ActionEvent *paeFirst)
    {
      result_t r = FAIL;

      if ((r = shout()) == SUCCESS)
	{
	  paeFirst->atCode = ACTION_REPLY_INVITATION;
	  rescheduleHeadEvent(ticPrime + SLOT_TICK, 0);
	}
      else 
	{removeEvent();}

      return r;
    }

  /* The node is, in the order of priority,
     1. a shouter: send packets with the strongest signal that it
     may use in future.
     2. a whisperer
     3. a listener */
  result_t detectInterference() {
    struct ActionEvent *paeFirst = peekActionEvent();
    result_t r = SUCCESS;

    clearIHistory(lAbsSuperSlotNo);
    if (paeFirst)
      {
	switch (paeFirst->atCode)
	  {
	  case ACTION_SHOUT:
	    doShout(paeFirst);

	    break;

	  case ACTION_WHISPER:
	    r = whisper(paeFirst->maDest);
	    removeEvent();

	    break;

	  case ACTION_LISTEN:
	    r = listenReport();
	    removeEvent();
	    break;

	  default:
	    break;
	  } // switch
      } // if paeFirst

    return r;
  } // detectInterference

  /* Examine the result of an interference test.
     The information of the test is in the first action event.
     If there are more interfering candidates, transit to DL_DETECT_SPECIFIC.
     Otherwise, transit to DL_IDLE. */
  result_t examineTest()
    {
      struct ActionEvent *paeFirst;
      result_t r = SUCCESS;

      KNOCK0;

      if ((paeFirst = peekActionEvent()) &&
	  (paeFirst->atCode == ((unsigned char)ACTION_EXAMINE_TEST)))
	{
	  switch (stDfa)
	    {
	    case DL_DETECT_SPECIFIC:
	      if ((isCleanIHistory(paeFirst->lNo)) &&
		  (trCur.cArrived))
		{
		  // Test result is negative
		  updateRi(trCur.maCandidate, -1, -1);
		} // if isCleanIHistory
	      else
		{
		  // Interference detected for the currently tested node
		  updateRi(trCur.maCandidate, 1, -1);
		}

	      break;

	    default:
	      ;
	    } // switch

	  removeEvent();
	  zeroIHistory();
	  trCur.maCandidate = selectCandidate();
	  
	  if (trCur.maCandidate == TOS_BCAST_ADDR)
	    {
	      stDfa = DL_IDLE;
	    } // no candidate left
	  else
	    {
	      // There are more candidates
	      stDfa = DL_DETECT_SPECIFIC;
	    }

	} // if the action event is ACTION_EXAMINE_TEST
      else
	{
	  r = FAIL;
	} // else the action event is ACTION_EXAMINE_TEST

      // LEAVE;

      return r;
    } // examineTest

  // Work following the instruction in the action event queue.
  result_t work()
    {
      result_t r;
      struct ActionEvent *paeFirst;
      MacAddress maDest;
      long l;

      KNOCKREC0(0x3055);

      queueKeeping();
      paeFirst = peekActionEvent();

      if (!paeFirst)
	{
	  // LEAVE;

	  return SUCCESS;
	}

      switch (paeFirst->atCode)
	{
	case ACTION_SEND:
	  // need to send a packet
	  queueKeeping();

	  // LEAVE;

	  // unprint4(ticPrime, paeFirst->atCode, 0x96000000, 0x95000000);
	  r = transmitPacket();
	  dbg(DBG_AM, "PRIME:finished transmitPacket@%lx\n", ticPrime);

	  break;

	case ACTION_COORDINATE:

	  // LEAVE;

	  // need to send the coordinate packet and reschedule it
	  maDest = paeHead->maDest;
	  rescheduleHeadEvent(ticPrime + MISH_COORDINATE_INTERVAL,
			      ticPrime + MISH_COORDINATE_INTERVAL);
	  r = sendCoordinateControlPacket(maDest);
	  break;

	case ACTION_REPLY_INVITATION:
	  maDest = paeHead->maDest;
	  l = TickToAbsSuperSlotNo(paeHead->tStart - SLOT_TICK);
	  removeEvent();

	  // LEAVE;

	  r = replyInvitation(maDest, l);

	  break;

	case ACTION_EXAMINE_TEST:

	  // LEAVE;
	  
	  r = examineTest();

	  break;

	default:
	  /* unprint4(ticPrime, nQSize + ((long)nEqSize << 16), 
	     0xff, paeFirst->atCode + 0x99999900);*/

	  queueKeeping();

	  // LEAVE;

	  r = SUCCESS;
	  break;
	} // switch paeFirst->atCode
	
      return r;
    } // work

  /* Yield to other nodes but needs to send out shouting packets */
  result_t yield()
    {
      result_t r = SUCCESS;
      struct ActionEvent *paeFirst = peekActionEvent();
      static int sRot;

      if (sRot > 0)
	{
	  sRot --;
	}

      if (paeFirst && paeFirst->atCode == ((unsigned char)ACTION_SHOUT))
	{r = doShout(paeFirst);}
      else
	{
	  KNOCK0;

	  // do some bookkeeping of the queues
	  queueKeeping();

	  // LEAVE;

	  if (!sRot)
	    {
	      sRot = 8;
	      // unprint4(ticPrime, dInfo + (((long)dMe) << 16), nQSize, 0x33000000+cDlState);
	    }
	} // else shout

      return r;
    } // yield

  // send packets
  task void fire()
    {
      // todo: sync mechanism needs to be carefully designed
      result_t r = SUCCESS;

      VOID_KNOCK(0x5505);

      // switch (scheduleSlot())
      switch (scheduleHardSlot())
	{
	case COMPETING_SYNC:

	  r = syncControl();

	  break;

	case YIELD:

	  r = yield();

	  break;

	case INVITE_INTERFERE_ME:

	  r = inviteInterference();

	  break;

	case DETECT_INTERFERENCE:

	  r = detectInterference();

	  break;

	default:
	  r = work();
	} // switch

      if (r != SUCCESS)
	{
	  // report error
	  dbg(DBG_AM, "PRIME: something wrong in fire\n");
	}

      cPrimeTimerEventPending = 0;

      LEAVE;

      return;
    } // fire

  // calculate numbers
  void calcNo()
    {
      unsigned long lAbsSlotNo = TickToAbsSlotNo(ticPrime);
      lAbsSuperSlotNo = AbsSlotToAbsSuperSlotNo(lAbsSlotNo);
      nSuperSlotNo = AbsSlotToSuperSlotNo(lAbsSlotNo);
      nSlotNo = TickToSlotNo(ticPrime);

      dbg(DBG_AM, "PRIME:calcNo@%lx:AS %lx, S: %x, ASS %lx, SS %x\n",
	  ticPrime, lAbsSlotNo, nSlotNo, lAbsSuperSlotNo, nSuperSlotNo);
      /*
      if (nSlotNo & 1)
	{
	  call Leds.yellowOn();
	}
      else
	{
	  call Leds.yellowOff();
	  }*/

    } // calcNo

  // Effective slot timer fires at the beginning of effective slots
  /* Actually, competing packets can be sent after the beginning of
     a slot and before the beginning of an effective slot. This is
     not implemented in this version */
  result_t fireEffectiveSlot() {
    result_t r = SUCCESS;

    calcNo();

    // dbg(DBG_AM, "EffectiveSlotTimer fired tick:%lx\n", ticPrime);

    if (!cPrimeTimerEventPending)
      {
	cPrimeTimerEventPending = 1;
	post fire();
      }

    return r;
  } // fireEffectiveSlot

  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  event result_t EffectiveSlotTimer.fired() {
    return SUCCESS;
  }
  
  default event result_t sendDone() {
    return SUCCESS;
  }

  /* Add a message send request to the message send request queue.
     Pre: pmsgOut must contain the valid destination address */
  unsigned int enQueue(CellPtr pmsgOut)
    {
      MacAddress maDest = pmsgOut->addr;
      MsgSendReq *pmsr;
      int nPrevQTail = nQTail;

      if (!pmsgOut)
	{return 0xffff;}

      if (nQSize >= PRIME_QUEUE_LIMIT - 1)
	{
	  // /////// Removing the last msg for the last event might be better
	  // /////// should restore dehead logic deHead(); 
	  return (unsigned int)(-2);
	} // msg queue full

      // fill in the queue
      pmsr = &msrQueue[nQTail];
      nQTail = (nQTail+1) % PRIME_QUEUE_SIZE;
      nQSize++;

      if(maDest == (uint16_t)TOS_BCAST_ADDR ||maDest == (uint16_t)TOS_UART_ADDR  )
	{
	  pmsr->confirmed = 1;
	  pmsr->to_retry = PRIME_BCAST_RETRY;
	}
      else 
	{
	  pmsr->confirmed = 3; // //////// confirmation removed
	  pmsr->to_retry = PRIME_MAX_RETRY;
	}

      pmsr->sent = 0;
      pmsr->pMsg = pmsgOut;
      pmsr->cNumLink = 0;

      dbg(DBG_AM, 
	  "PRIME: enqueue@0x%lx pmsr %p, to %x/%p,now-q %d/%d/%d, 9th %x,cfm %d\n",
	  ticPrime, pmsr, maDest, pmsgOut, nQHead, nQTail, nQSize, 
	  ((char *)pmsgOut)[8], pmsr->sent, pmsr->confirmed);

      return (nPrevQTail);
    } // enQueue

  /* Add a new event to the action event queue */
  // index: index to msrQueue
  result_t addEvent(struct ActionEvent *paeNew)
    {
      struct ActionEvent *paeNow = paeHead, *paePrev = paeHead;

#ifdef DEBUGGING
      if (checkAQ() == FAIL)
	{
	  // DBG_HALT(1);
	  uprint4((long)paeHead + (((long)(paeHead->paeNext)) << 16),
		  (paeHead->paeNext) ? ((long)(paeHead->paeNext->paeNext)) : 0,
		  ((paeHead->paeNext && paeHead->paeNext->paeNext) ?
		   ((long)paeHead->paeNext->paeNext->paeNext) : 0)
		  + (((long)paeTail) << 16),
		  dRemoveEvent + 0x77ee0000);
	  gcNoPrint = 1;
	}

      if (!(paeNew->tStart))
	{
	  // uprint4(ticPrime, dGoodMe, paeNew->tExpire, 0x77777777);
	  showLeds(7);
	  DBG_HALT(0);
	}

      dbg(DBG_AM, "PRIME:addEvent@%lx:h-%p,t-%p,s-%d\n", 
	  ticPrime, paeHead, paeTail, nEqSize);
#endif

      paeNew->paeNext = 0;

      /* quick path: if tStart is later than the tail event, 
	 post as tail. */
      if (paeTail && ((paeTail->tStart) <= (paeNew->tStart)))
	{
		  if (((unsigned int)paeNew) == 0x1081)
		    {
		      if (((uint16_t)paeTail) != 0x106f)
			{
			  showLeds(5);
			  DBG_HALT(0);
			}
		    } // 1081
	  paeTail->paeNext = paeNew;
	  paeTail = paeNew;
	}
      else
	{
	  // normal path, search and insert
	  while (paeNow && ((paeNow->tStart) < (paeNew->tStart)))
	    {
	      paePrev = paeNow;
	      paeNow = paeNow->paeNext;
	    }

	  if (!paePrev)
	    {
	      // empty queue
	      paeHead = paeNew;
	    }
	  else 
	    {
	      if (paeHead == paeNow)
		{
		  // need to insert before the head
		  paeNew->paeNext = paeHead;
		  paeHead = paeNew;
		}
	      else
		{
		  if (paePrev->paeNext != paeNow)
		    {
		      showLeds(1);
		      DBG_HALT(0);
		    }

		  if (((unsigned int)paeNew) == 0x1093)
		    {
		      if (((uint16_t)paePrev) == 0x106f && 
			  (paePrev->paeNext) == 0)
			{
			  // showLeds(3);
	  uprint4((long)paeHead + (((long)(paeHead->paeNext)) << 16),
		  (paeHead->paeNext) ? ((long)(paeHead->paeNext->paeNext)) : 0,
		  ((paeHead->paeNext && paeHead->paeNext->paeNext) ?
		   ((long)paeHead->paeNext->paeNext->paeNext) : 0)
		  + (((long)paeTail) << 16),
		  dRemoveEvent + 0x77990000);
	  gcNoPrint = 1;
			  // DBG_HALT(0);
			}
		    } // 1093

		  paeNew->paeNext = paeNow;
		  paePrev->paeNext = paeNew;
		  
		}
	    } // else paePrev

	  paeTail = paeNow ? paeTail : paeNew;
	}

#ifdef DEBUGGINGno
      if (gnGeneralLevel > 1)
	{
	  showLeds(3);
	  DBG_HALT(0);
	}
#endif

      nEqSize++;

#ifdef DEBUGGINGno
      if (checkAQ() == FAIL)
	{
	  // showLeds(2);
	  // DBG_HALT(0);
	  uprint4((long)paeHead + (((long)(paeHead->paeNext)) << 16),
		  (paeHead->paeNext) ? ((long)(paeHead->paeNext->paeNext)) : 0,
		  ((paeHead->paeNext && paeHead->paeNext->paeNext) ?
		   ((long)paeHead->paeNext->paeNext->paeNext) : 0)
		  + (((long)paeTail) << 16),
		  dRemoveEvent + 0x77660000);
	  gcNoPrint = 1;
	}
      else
	{
	  uprint4((long)paeHead + (((long)(paeHead->paeNext)) << 16),
		  (paeHead->paeNext) ? ((long)(paeHead->paeNext->paeNext)) : 0,
		  ((paeHead->paeNext && paeHead->paeNext->paeNext) ?
		   ((long)paeHead->paeNext->paeNext->paeNext) : 0)
		  + (((long)paeTail) << 16),
		  dRemoveEvent + 0x77aa0000);
	}

      /*      if ((!paeHead) && nEqSize)
	{
	  showLeds(5);
	  DBG_HALT(0);
	  }*/
      if (!(paeNew->tStart))
	{
	  // uprint4(ticPrime, dGoodMe, paeNew->tExpire, 0x77777777);
	  showLeds(7);
	  DBG_HALT(0);
	}

      if (!(paeHead->tStart))
	{
	  uprint4(ticPrime + (((long)nEqSize) << 16), 
		  dGoodMe + ((paeNew->tStart) << 16), 
		  (paeNew->tExpire) + (dFuncID << 16),
		  ((long)paeHead) + 0x77880000);
	  showLeds(7);
	  DBG_HALT(0);
	}
      // dumpActionQueue();
#endif
      return SUCCESS;
    } // addEvent

  result_t checkAQ()
    {
      struct ActionEvent *pae0 = paeHead;
      int n = 0;

      while (pae0)
	{
	  n++;
	  pae0 = pae0->paeNext;
	}

      if (nEqSize != n)
	{
#ifdef DEBUGGINGno
	  /* uprint4(ticPrime, dGoodMe + (lPacketsToSend << 16), 
		  n + (((long)nEqSize) << 16), 
		  0x77990000); */
	  struct ActionEvent *pae5;

	      pae5 = (paeHead->paeNext && paeHead->paeNext->paeNext && paeHead->paeNext->paeNext->paeNext) ?
		(paeHead->paeNext->paeNext->paeNext->paeNext) : 0;

	      uprint4((long)paeHead + (((long)(paeHead->paeNext)) << 16),
		      ((paeHead->paeNext) ? ((long)(paeHead->paeNext->paeNext)) : 0)  + (((long)n) << 24) + (((long)nEqSize << 16)),
		      ((paeHead->paeNext && paeHead->paeNext->paeNext) ?
		       ((long)paeHead->paeNext->paeNext->paeNext) : 0)
		      + (((long)paeTail) << 16),
		      ((unsigned long)pae5) + (((unsigned long)dRemoveEvent) << 24) + (unsigned long)0x22000000);
	      //  showLeds(4);
	      // DBG_HALT(0);
	      gcNoPrint = 1;
#endif

	  // showLeds(1);
	  // DBG_HALT(0);

	  return FAIL;
	}

      /* if (!(paeHead->tStart))
	{
	  // uprint4(ticPrime, dGoodMe, paeNew->tExpire, 0x77779999);
	  // showLeds(5);
	  // DBG_HALT(0);
	}
      */
      /*      if ((!paeHead) && nEqSize)
	{
	  dbg(DBG_AM, "SPRIME: halted @ %lx\n", ticPrime);
	  showLeds(6);
	  DBG_HALT(0);
	  }*/

      return SUCCESS;
    } // checkAQ

  // The event being removed must be the first event in the queue
  void removeEvent()
    {
      // need to protect it outside
      
      struct ActionEvent *pae = paeHead;
      /*      
	      if (!paeHead)
	      {
	      dPanic = 1;
	      dbg(DBG_AM, "PRIME: very strange\n");

	      return;
	      } 
      */

      switch (paeHead->atCode)
	{
	case ACTION_SEND:
	  // msrQueue[paeHead->index2msr].to_retry = 0;
	  msrQueue[paeHead->index2msr].cNumLink--;

	  break;

	default:
	  break;
	} // switch

      paeHead = paeHead->paeNext;
      staticFree(pae);
      
      if (dRemoveEvent >= 0)
	{
	  dRemoveEvent++;
	}

#ifdef DEBUGGINGno
      if (gnGeneralLevel > 1)
	{
	  showLeds(3);
	  DBG_HALT(0);
	}
#endif

      if (!(--nEqSize))
	{
	  // empty queue
	  paeTail = 0;
	}
      
#ifdef DEBUGGING
      dbg(DBG_AM, 
	  "PRIME: removeEvent: Event Queue Head %p Tail %p Size %x\n",
	  paeHead, 
	  paeTail,
	  nEqSize);

      // dumpActionQueue();

      if (checkAQ() == FAIL && (dRemoveEvent > 0))
	{
	  uprint4((long)paeHead + (((long)(paeHead->paeNext)) << 16),
		  (paeHead->paeNext) ? ((long)(paeHead->paeNext->paeNext)) : 0,
		  ((paeHead->paeNext && paeHead->paeNext->paeNext) ?
		   ((long)paeHead->paeNext->paeNext->paeNext) : 0)
		  + (((long)paeTail) << 16),
		  nEqSize + 0x77cc0000);
	  gcNoPrint = 1;
	  // showLeds(5);
	  // DBG_HALT(0);
	}
#endif
    } // removeEvent

  void abandonSending(CellPtr pmsgAbandon)
    {
      call Pool.free(pmsgAbandon);
      lNumMemFreed++;

      dbg(DBG_AM, ("PRIME:abandonSending: cannt transmit\n"));
    } // abandonSending

  // Send the packet, which must be in the message pool
  result_t sendPacket(char cType,
		      MacAddress maDest, 
		      uint8_t length, 
		      CellPtr data)
    {
      unsigned int nQPos;
      result_t r = SUCCESS;

#ifdef DUMP_MSGno
      dumpPacket(data);
#endif

      /* if the caller do not free memory after getting a 
	 returned value of failure, there couldbe memory leak. So 
	 I'd better free memory here.*/

      lPacketsToSend++;
      dMe = 0xcccc;
 
      KNOCK0FREE;

      dInfo = 0xcccc;

      /*if (data->addr == TOS_UART_ADDR)
	{
	  sendPriorityUARTPkt(data);
	  return SUCCESS;
	  }*/

      if ((nEqSize >= PRIME_EVENT_QUEUE_SIZE - 1) ||
	  (nQSize >= PRIME_QUEUE_LIMIT - 1))
	{
	  // Now FAIL is only signaled when the link is broken
	  // TOS_SIGNAL_EVENT(AM_MSG_SEND_FAIL)(data);
	  abandonSending(data);

	  // LEAVE;
	  return 0;
	}

      data->addr = maDest;
      nQPos = enQueue(data); // /////// need to avoid race condition with eq, q increase
      if ((r = postEvent(PRIME_INSERT_AFTER, 
			 ticPrime+PRIME_LISTEN_TIME+PRIME_GRACE, 
			 nQPos)) == SUCCESS)
	{
	  data->cSeq = nQPos;
	  data->length = length;
	  data->nSrc = TOS_LOCAL_ADDRESS;
	  data->type = cType;
	  data->group = TOS_AM_GROUP;
	  // unprint4(ticPrime, data->nSrc, data->addr, 0x94000000);
	}
      else
	{
	  dbg(DBG_AM, 
	      "PRIME: transmitPacket@%lx: insufficient mem\n", 
	      ticPrime);
	  msrQueue[nQPos].to_retry = 0;
	  msrQueue[nQPos].confirmed = 7;
	  msrQueue[nQPos].sent = 7;
	  abandonSending(data);
	  purgeQueue();
	}
  
      // LEAVE;

      return r;
    } // sendPacket

  /* Sending without synchronizing with others. */
  result_t sendPriorityPacket(char cType,
			      MacAddress maDest, 
			      uint8_t length, 
			      CellPtr data)
    {
      unsigned int nQPos;
      result_t r = SUCCESS;

#ifdef DUMP_MSGno

      {
	int i;
	CellPtr pMsg;
    
	pMsg = data;
	// dbg(DBG_AM, ("AM : Send message: dumping: pMsg %x\n", pMsg)); 
	if (pMsg)
	  {
	    for(i = 0; i < sizeof(Cell); i++) {
	      dbg_clear(DBG_AM, ("%hhx,", ((char*)pMsg)[i]));
	    }
	    // dbg(DBG_AM, ("\n"));
	  }
      }

#endif

      /* if the caller do not free memory after getting a 
	 returned value of failure, there couldbe memory leak. So 
	 I'd better free memory here.*/

      lPacketsToSend++;
      data->addr = maDest;
      data->length = length;
      data->nSrc = TOS_LOCAL_ADDRESS;
      data->type = cType;
      pmsgPriority = data;
      sendPriority();

      return r;
    } // sendPriorityPacket

  void uprint(long lShow)
    {
      DebugPacket *pdpDebug = (DebugPacket *)(msgPriority.data);

      if (gcNoPrint)
	{
	  return;
	}

      pdpDebug->l4 = lShow;
      pmsgPriority = &msgPriority;
      pmsgPriority->addr = TOS_UART_ADDR;
      sendPriorityUART();
      // sendPriorityPacket(PKT_DEBUG, TOS_UART_ADDR, 25, &msgPriority);
    } // sendUart

  void uprint4(long l1, long l2, long l3, long l4)
    {
      DebugPacket *pdpDebug = (DebugPacket *)(msgPriority.data);

      if (gcNoPrint)
	{
	  return;
	}
      
      pdpDebug->l1 = l1;
      pdpDebug->l2 = l2;
      pdpDebug->l3 = l3;
      pdpDebug->l4 = l4;
      pmsgPriority = &msgPriority;
      pmsgPriority->addr = TOS_UART_ADDR;
      sendPriorityUART();
      dbg(DBG_AM, "SPRIME:uprint4: %lx, %lx, %lx, %lx\n", l1, l2, l3, l4);
      // sendPriorityPacket(PKT_DEBUG, TOS_UART_ADDR, 25, &msgPriority);
    } // sendUart

  task void acceptPacket()
    {
      CellPtr pmsgInPool = call Pool.copy(pmsgAccepted);
      
      VOID_KNOCK(0x5501);

      if (pmsgInPool)
	{
	  rRoomy = sendPacket(pmsgAccepted->type, pmsgAccepted->addr, 
			      pmsgAccepted->length, pmsgInPool);
	}

      // uprint4(ticPrime, pmsgAccepted->nSrc, pmsgAccepted->addr, 0x93000000);
      pmsgAccepted = 0;

      LEAVE;

      return;
    } // acceptPacket

  /* Send a packet which is not in the message pool.
     If there is room and the past packet has been processed,
     the new packet is recorded and will hopefully be put into
     the queue.
     If there is no room, record the packet for transmission
     if possible, but return a failure result. */     
  command result_t SendMsg.send[uint8_t id](uint16_t nAddr, 
					    uint8_t length, 
					    TOS_MsgPtr data)
    {
      result_t r;

#ifdef DEBUGGINGno
      static int nRot;
      
      static int nEnter, nThru;

      nEnter++;
      if (dGoodMe == 0x1102)
	{
	  if (nEnter - nThru > 16)
	    {
	      showLeds(dTransmitTask + 2);
	      DBG_HALT(0);
	    }
	}
      else
	{
	  nThru++;
	}
	
      nRot++;
      if (!(nRot & 0x1))
       {
	 uprint4(gnGeneralLevel, nEqSize, dGoodMe + (dMe << 16), 0x33770000);
       }

#endif

      KNOCK(FAIL, 0x5506);

      if (data->addr == TOS_UART_ADDR)
	{
	  // call Leds.yellowToggle();
	  sendPriorityUARTPkt((CellPtr)data);
	}

      data->addr = nAddr;
      data->length = length;
      data->type = id;

      if (pmsgAccepted)
	{
	  // unable to accept a packet right now
	  r = FAIL;
	}
      else
	{
	  pmsgAccepted = (CellPtr)data;
	  post acceptPacket();
	  r = rRoomy;
	}

      LEAVE;

      return r;
    } // SendMsg.send

  // This task makes up the lost TX_DONE event
  task void AM_TXdone()
    {
      CellPtr pmsg = pmsgTXdone;
  
      VOID_KNOCK(0x3301);

      pmsgTXdone = 0;
      bookkeepAfterSent(pmsg);

      LEAVE;

      return;
    }

  /* dispatch to the upper layer, which does not free the packet */
  task void dispatchUpward()
    {
      CellPtr pmsg;
  
      VOID_KNOCK(0x2201);

      KNOCKREC(0xbbbb);

      pmsg = pmsgArrived;
      pmsgArrived = 0;

      dbg(DBG_AM, "PRIME: dispatching message no %x\n", pmsg->type);

      // dispatch message
      signal ReceiveMsg.receive[pmsg->type]((TOS_MsgPtr)pmsg);
      call Pool.free(pmsg);

      LEAVE;
      
      return;
    }

  // This task makes up the lost TX_DONE event
  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    result_t r, dr;

    KNOCK(FAIL, 0x3303);

    dr = checkAQ();

    cUartBusy = 0;
    r = reportSendDone((CellPtr)msg, success);

    if (checkAQ() == FAIL && (dr == SUCCESS))
      {
	showLeds(3);
	DBG_HALT(0);
      }

    LEAVE;

    return r;
  }

  void bookkeepAfterSent(CellPtr pmsgDone)
    {
      char cIndex; // -- lin = VAR(qhead);

      cMacState = 0;
      nRecycle = 0;

      /*if (MUTEX_LOCKED)
	{
	  if (pmsgTXdone)
	    {
	      last_tx_done = ticPrime;

#ifdef ICE_DBG 	  
	      TOS_CALL_COMMAND(AM_DBG_SEND)("AM: TX_DONE lost");
#endif	  
	    }
	  else
	    {
	      pmsgTXdone = pmsgDone;
	      post AM_TXdone();
	    } // else pmsgTXdone

	  return;
	} // if critical
      else
	{last_tx_done = ticPrime;}

      */

      KNOCKREC(0xdddd);

      dbg(DBG_AM, "MAC_BUSY Avaialbe NOW\n");
      dInfo = 0xdddd;
      /* if (pmsg == &VAR(confirm))
	 {
	 ShiftConfirm();
	 }
	 else
	 {
      */
      // it is safer to use qsize because .sent may have a legacy value
      // And I guess &VAR(msrQueue) will not return what we expect to get
      // Tian's suggestion: try to send new packets first. Not sure of
      // whether this is worthy of the code, but implementing it anyway.
      // And will observe the performance to try to justify it.
      for (cIndex=0; cIndex<nQSize; cIndex++)
	{
	  MsgSendReq *pmsrNow = &(msrQueue[(nQHead+cIndex) % PRIME_QUEUE_SIZE]);
	  if ( pmsrNow->pMsg== pmsgDone && !(pmsrNow->sent))
	    {
#ifdef DEBUGGING
	      dbg(DBG_AM, 
		  "AM: tick 0x%x : set sent to 9 for index:head %x. p in queue: %x\n", 
		  ticPrime, nQHead, pmsrNow->pMsg); 
#endif
	      pmsrNow->sent = 9;

#ifdef nouse
	      if (pmsrNow->confirmed)
		{
		  dbg(DBG_AM, 
		      "PRIME: bookkeepAfterSent@%#lx:confirmed before sent. pmsrNow %p, pmsrNow->pMsg %p\n", 
		      ticPrime, pmsrNow, pmsrNow->pMsg); 
		  // ///////TOS_SIGNAL_EVENT(AM_MSG_SEND_DONE_EX)(pmsrNow->pMsg, 1);
	     	
		  // /////// purgeQueue();
		} // if confirmed
#endif
	      break;
	    } // if == pmsg
	} // for cIndex
      /*
	} // else != &confirm
      */
      dbg(DBG_AM, 
	  "PRM$bookkeepAfterSent: tick %#x state reset to 0, qsize %d, cDlState: %d\n", 
	  ticPrime, nQSize, cDlState);

      // LEAVE;
    } // bookKeepAfterSend

  void reportRadioSendDone(CellPtr pmsgDone, result_t rOk)
    {
      // unprint(0x49000000);

      bookkeepAfterSent(pmsgDone);
      
      if (pmsgDone->type == PKT_CONTROL)
	{
	  ControlHeader *pchDone = (ControlHeader *)(pmsgDone->data);
	  switch (pchDone->cptType)
	    {
	    case PKT_CONTROL_WHISPER:
	    case PKT_CONTROL_SHOUT:
	      continueSend();
	      return;
	      break;

	    default:
	      break;
	    } // switch
	} // pmsgDone->type = PKT_CONTROL

      // /////// call Pool.free(pmsgDone);

      /* Maybe there is still enough time to do another
	 transmission. */
      post fire();

      lNumSent++;

      return;
    } // reportRadioSendDone

  event result_t RadioSend.sendDone(TOS_MsgPtr pmsgDone, result_t success) {
    // unprint(0x93000000 + (((unsigned long)(pmsgDone->type))<<16) + success);

    result_t r;

    KNOCK(FAIL, 0x3302);

    reportRadioSendDone((CellPtr)pmsgDone, success);
    r = reportSendDone((CellPtr)pmsgDone, success);

    LEAVE;

    return r;
  } // RadioSend.sendDone

  InputQueue *findAllocate(short src)
    {
      int i, j=0, min_freq=iqGot[0].freq;
      InputQueue *piqCur;

      for (i=0; i<PRIME_INPUT_QUEUE_NUM; i++)
	{
	  piqCur = &(iqGot[i]);
	  // // dbg(DBG_AM, ("PRIME: FindAllocate: picCur %x\n", piqCur));
      
	  if (src == piqCur->src && piqCur->life)
	    return piqCur;
	  else
	    {
	      if (piqCur->freq < min_freq)
		{
		  j = i;
		  min_freq = piqCur->freq;
		} // if < min_freq
	    } // else src == picCur->nSrc
	} // for i

      evacuate(j);
      piqCur = &(iqGot[j]);
      piqCur->src = src;

      // dbg(DBG_AM, ("PRIME: FindAllocate: picCur %p\n", piqCur));

      return piqCur;
    } // Find Allocate

  void clearBit(InputQueue *piqCur, unsigned char cNew)
    {
      unsigned char 
	cOldBehind = ((piqCur->expected) + PRIME_INPUT_QUEUE_SIZE - PRIME_INPUT_QUEUE_BEHIND) % PRIME_INPUT_QUEUE_SIZE,
	cBeginByte = BYTE_OFFSET(cOldBehind),
	cBeginBit = BIT_OFFSET(cOldBehind),
	cNewBehind = (cNew + PRIME_INPUT_QUEUE_SIZE - PRIME_INPUT_QUEUE_BEHIND) % PRIME_INPUT_QUEUE_SIZE,
	cEndByte, cEndBit,
	*pcQueue,
	cMask;
      char cInterval;
      int i;

      pcQueue = piqCur->queue;
      if (!INORDER(cOldBehind, cNewBehind, RMINUS(piqCur->expected, 1, PRIME_INPUT_QUEUE_SIZE), PRIME_INPUT_QUEUE_SIZE))
	{
	  cNewBehind = RMINUS(piqCur->expected, 1, PRIME_INPUT_QUEUE_SIZE);
	} // if INORDER

      cEndByte = BYTE_OFFSET(cNewBehind);
      cEndBit = BIT_OFFSET(cNewBehind);
      cInterval = (cEndByte + PRIME_INPUT_QUEUE_SIZE - cBeginByte) % PRIME_INPUT_QUEUE_SIZE;

      if (cBeginBit)
	{
	  cMask = (unsigned char)(((signed char)0x80) >> (7-cBeginBit));
	  pcQueue[cBeginByte] &= cMask;
	  cInterval--;
	  cBeginByte++;
	}

      if (cEndBit)
	{
	  cMask = (unsigned char)(1 << (7-cEndBit));
	  pcQueue[cBeginByte] &= cMask;
	  cInterval--;
	}

      for (i=0; i<=cInterval; i++)
	{
	  unsigned int j = (cBeginByte + i) % PRIME_INPUT_QUEUE_SIZE;
	  pcQueue[j] = 0;
	} // for
    } // clearBit

  CellPtr processPacket(CellPtr pmsgIn) {
    CellPtr pmsgR;

    switch (pmsgIn->type)
      {
      case PKT_CONTROL:
	pmsgR = processControlPacket(pmsgIn);
	break;
	
      default:
	pmsgR = processNormalPacket(pmsgIn);
      }

    return pmsgR;
  } // processPacket

  // Look at the queue corresponding to the src, then set the
  // bit to 1 if it is within the expected range. Return whether
  // the packet is a new one.
  char updateIQ(short src, char seq)
    {
      InputQueue *piqHit = findAllocate(src);
      unsigned char cMask, *pcByte;

      if (!(piqHit->life))
	{
	  // empty queue
	  piqHit->expected = seq;
	}

      //////// here we simplify the scenario by assuming the seq no is not broken too far apart. A better way would be to use peer-to-peer seq no.
      if (((unsigned)((((unsigned char)seq) + (PRIME_INPUT_QUEUE_SIZE - piqHit->expected)) % PRIME_INPUT_QUEUE_SIZE)) < PRIME_INPUT_QUEUE_AHEAD)
	{
	  // within range, ahead
	  // Need to adjust expected seq, and clear a segment of bits
	  unsigned char cNewExpected = ((unsigned char)(seq+1)) % PRIME_QUEUE_SIZE;
      
	  clearBit(piqHit, cNewExpected);
	  piqHit->expected = cNewExpected;
	  // dbg(DBG_AM, ("PRIME: updateIQ: new expected: %d\n", (int)cNewExpected));
	} // if
      else
	{
	  if (((piqHit->expected + PRIME_INPUT_QUEUE_SIZE - ((unsigned char)seq)) % PRIME_INPUT_QUEUE_SIZE) > PRIME_INPUT_QUEUE_BEHIND)
	    {
	      // out of range
	      dPanic = 1;

	      if (!(dPanicInfo))
		dPanicInfo = dInfo;

	      if (!(dPanicMe))
		dPanicMe = dMe;
#ifdef ICE_DBG 
	      call AM_DBG_SEND3("N", dPanicInfo, dPanicMe);
#endif	  
	      // dbg(DBG_AM, ("PRIME: panic(UpdateIQ): panic set to 1\n"));

	      return 0;
	    }
	} // else

      piqHit->freq++;
      cMask = (((unsigned char)1) << BIT_OFFSET(seq));
      pcByte = &((piqHit->queue)[BYTE_OFFSET(seq)]);

      if ((*pcByte) & cMask)
	{
	  return 0;
	}
      else
	{
	  (*pcByte) |= cMask;

	  if (!(piqHit->life))
	    piqHit->life = 1;

	  return 1;
	}
    }

  CellPtr processNormalPacket(CellPtr pmsgIn) {
    dbg(DBG_AM, 
	"PRIME received: tick %#lx AM_address = %hx, %hhx @ %p\n", 
	ticPrime, pmsgIn->addr, pmsgIn->type, pmsgIn);
   
    if (//pmsgIn->crc == 1 && // Uncomment this line to check crcs
	/* pmsgIn->group == TOS_AM_GROUP && */
	(pmsgIn->addr == TOS_BCAST_ADDR ||
	 pmsgIn->addr == TOS_LOCAL_ADDRESS))
      {
#ifdef DEBUGGING
	// Debugging output
	{
	  int i;
	  // dbg(DBG_AM, ("AM Received message at %p:\n\t", pmsgIn));
	  for(i = 0; i < sizeof(Cell); i ++) {
	    dbg_clear(DBG_AM, "%hhx,", ((char*)pmsgIn)[i]);
	  }
	  // dbg(DBG_AM, ("\n"));
	  // dbg(DBG_AM, ("AM_type = %d\n", type));
	}
#endif

#ifdef ICE_DBG 
	// debug
	// call AM_DBG_SEND3("G", pmsgIn->addr, pmsgIn->cSeq);
#endif
	//send message to be dispatched.
	// invoke the corresponding handler defined by pmsgIn->type
	
	if (updateIQ(pmsgIn->nSrc, pmsgIn->cSeq) || pmsgIn->addr == (uint16_t)TOS_BCAST_ADDR)
	  {
	    // valid pmsgIn received. copy to local buffer and dispatch.
	    /////// seems inefficient. an event is better than _REC?
#ifdef ICE_DBG 
	    // /////// debug
	    // /////// call AM_DBG_SEND3("U", pmsgIn->addr, pmsgIn->cSeq);
#endif 
	    dTotal++;
	    if (!(pmsgIn = call Pool.copy(pmsgIn)))
	      {
		// dbg(DBG_AM, ("PRIME: pool full\n"));
#ifdef ICE_DBG 	    
		// call AM_DBG_SEND("PRIME: POOL FULL");
		PrintPoodInfo("RX");
#endif	    
	      }
	    else
	      {
		// dbg(DBG_AM, ("PRIME: RX event: pmsgIn set to %p\n", pmsgIn));
		if (!(pmsgArrived))
		  {
		    pmsgArrived = pmsgIn;
		    post dispatchUpward();
		    // dbg(DBG_AM, ("PRIME: Posting dispatch task\n"));
		  }
		else
		  {
#ifdef ICE_DBG 	      	
		    call AM_DBG_SEND("PRIME: OVERLAP DISPATCH");
#endif		
		  }
	      } // else copy_pmsgIn
	  } // if UpdateIQ
	else
	  dbg(DBG_AM, "PRIME: duplicate packet\n");
      }
    
    return pmsgIn;
  } // processNormalPacket

  task void restartPrimeTimer()
    {
      VOID_KNOCK(0x3309);

      call PrimeTimer.stop();
      call PrimeTimer.start(TIMER_REPEAT, TICK_TIME);
      uprint4(ticPrime, ticNextStart, nNumBitSuperSlotInPeriod, 0xb1000000);

      LEAVE;
    }

  CellPtr processSyncControlPacket(CellPtr pmsgIn) {
    SyncPacket *pspktIn = (SyncPacket *)pmsgIn->data;
    // Tick ticTransmission = ticPrime - ticLastStartSym;
    
    findAllocate(pmsgIn->nSrc);
    
    if (pspktIn->ticTime - ticPrime + 1 > ACCEPTABLE_CLOCK_ERROR)
      {
	// call EffectiveSlotTimer.stop();
	ticPrime = pspktIn->ticTime + 1;
	// (ticTransmission <= HIGHEST_TRANSMISSION_TIME ? ticTransmission : 0);
	// /////// nNumBitSlotInSuperSlot = pspktIn->nNumBitSlotInSuperSlot;
	nNumBitSuperSlotInPeriod = pspktIn->nNumBitSuperSlotInPeriod;
	// ticNextStart = pspktIn->tNextStart;
	ticNextStart = ticPrime + SLOT_TICK + GRACE_BEFORE;
	// cEffectiveSlotTimerRunning = 0;
	ticTimeSyncTimer = 0;
	post restartPrimeTimer();

	dbg(DBG_AM, "PRIME: ticPrime set to %lx\n", ticPrime);
      }

    return pmsgIn;
  } // processSyncControlPacket


  CellPtr processWhisperControlPacket(CellPtr pmsgIn) {
    if (pmsgIn->addr == TOS_LOCAL_ADDRESS)
      {
	decreaseIHistory(lAbsSuperSlotNo & NUM_BIT_IHISTORY);
      } // if pmsgIn->addr == local

    return pmsgIn;
  } // processWhisperControlPacket

  void dumpPacket(CellPtr pmsg)
    {
      if (pmsg)
	{
	  char *p0 = (char *)(pmsg->data),
	    *p1 = ((char *)pmsg)+(sizeof(Cell));
      
	  dbg(DBG_AM, "PRIME:dumpPacket: pmsg %x\n", pmsg);
	  dbg(DBG_AM, "addr:%x ty:%hhx grp:%hhx  len%hhx nSrc%x cSeq:%hhx\n",
	      pmsg->addr, pmsg->type, pmsg->group, pmsg->length,
	      pmsg->nSrc, pmsg->cSeq); 

	  while (p0<p1)
	    {
	      dbg_clear(DBG_AM, "%hhx,", *p0++);
	    }
	  dbg(DBG_AM, ("\n"));
	} // pmsg
    } // dumpPacket

  /* Schedule to whisper at the DETECT_INTERFERENCE_SLOT of the
     super slot specified. */
  void scheduleWhisper(unsigned long lNo, MacAddress maTo)
    {
      showLeds(0);
      DBG_HALT(0);

      if (nEqSize < PRIME_EVENT_QUEUE_SIZE)
	{
	  struct ActionEvent *paeNew = 
	    (struct ActionEvent *)(staticMalloc(sizeof(struct ActionEvent)));

	  paeNew->tStart = AbsSuperSlotToTick(lNo) +
	    SlotToNumTick(DETECT_INTERFERENCE_SLOT_NO);
	  paeNew->tExpire = (paeNew->tStart) + SlotToNumTick(1) - 1;
	  paeNew->mode = 0;
	  paeNew->atCode = ACTION_WHISPER;
	  paeNew->maDest = maTo;

	  addEvent(paeNew);
	  
	  dbg(DBG_AM, 
	      "PRIME$scheduleWhisper@%lx:to %x @ (SS)%lx--%lx\n", 
	      ticPrime, maTo, lNo, paeNew->tStart);

	  return;
	} // if eq not full
      else
	{
	  return;
	}
    } // scheduleWhisper

  /* Schedule to shout at the DETECT_INTERFERENCE_SLOT of the
     super slot specified. */
  void scheduleShout(unsigned long lNo, MacAddress maDest)
    {
      showLeds(0);
      DBG_HALT(0);

      if (nEqSize < PRIME_EVENT_QUEUE_SIZE)
	{
	  struct ActionEvent *paeNew = 
	    (struct ActionEvent *)(staticMalloc(sizeof(struct ActionEvent)));

	  paeNew->tStart = AbsSuperSlotToTick(lNo) +
	    SlotToNumTick(DETECT_INTERFERENCE_SLOT_NO);
	  paeNew->tExpire = (paeNew->tStart) + SlotToNumTick(1) - 1;
	  paeNew->mode = 0;
	  paeNew->atCode = ACTION_SHOUT;
	  paeNew->maDest = maDest;

	  addEvent(paeNew);

#ifdef DEBUGGING
	  uprint4(paeNew->tStart, 
		  maDest + (((long)nNumBitSuperSlotInPeriod) << 16),
		  nMyFirstSuperSlot + (((long)nMyLastSuperSlot) << 16),
		  0xb6000000+(((unsigned long)cDlState)<<8));
	  dbg(DBG_AM, 
	      "PRIME$scheduleShout@%#lx: shout to %x @ (SS)%lx--%lx\n", 
	      ticPrime, maDest, lNo, paeNew->tStart);
#endif
	  return;
	} // if eq not full
      else
	{
	  return;
	}
    } // scheduleShout

  /* If the invitation is for this node or if the iteration reaches 1,
     schedule to shout. */
  CellPtr processInviteInterferenceControlPacket(CellPtr pmsgIn) {
    InviteInterferencePacket *piipIn = 
      (InviteInterferencePacket *)(pmsgIn->data);

    dbg(DBG_AM, 
	"MISH: processInviteInterferenceControlPacket t%lx\n", 
	ticPrime);

    if (piipIn->maWhisperer == TOS_LOCAL_ADDRESS)
      {
	// need to scheduel to whisper
	scheduleWhisper(piipIn->lAppointAbsSuperSlot, pmsgIn->nSrc);
      } // else if whisper
    else if ((piipIn->maShouter== TOS_LOCAL_ADDRESS) ||
	     (piipIn->lIteration == 1))
      {
	/* need to schedule to shout and send a reply to the 
	   inviter. To make sure the reply is sent only when the
	   shouting is done, that action will be scheduled later
	   after the first shouting action is executed. */
	scheduleShout(piipIn->lAppointAbsSuperSlot, piipIn->maInviter);
      }

    // forward invitation
    if (piipIn->lIteration > 1)
      {
	// need to forward to the next hop
	(piipIn->lIteration)--;
      } // if (piipIn->lIteration > 1)

    return pmsgIn;
  } // processInviteInterferenceControlPacket

  void simpleRouter(MacAddress maDest, CellPtr pmsgPacket)
    {
      sendPacket(pmsgPacket->type, maDest, pmsgPacket->length, pmsgPacket);
    }

  /* Invitation reply is sent to the inviter by the routers.
     Upon receiving a reply, the inviter needs to check whether
     an interference has occured in the shouting slot. */
  CellPtr processReplyInvitationControlPacket(CellPtr pmsgIn) {
    ReplyInvitationPacket *pripIn = 
      (ReplyInvitationPacket *)(pmsgIn->data);

    if (pripIn->maInviter == TOS_LOCAL_ADDRESS)
      {
#ifdef nouse
	char cInc = 
	  (cIHistory[(pripIn->lAppointAbsSuperSlotNo)] & NUM_BIT_IHISTORY) ?
	  2 /* pessimistic choice: disfavoring negative result */: 
	  -1;
	*/
#endif
	  updateRi(pripIn->maShouter, 0, -1);

	  if (/* for robustness. Actually this condition should always
		 hold when stDfa == DL_DETECT_SPECIFIC */
	      trCur.maCandidate == pripIn->maInviter)
	    {
	      trCur.cArrived = 1;
	    } // if trCur
      } // if pripIn

    return pmsgIn;
  } // processReplyInvitationControlPacket

  // todo: my first slotand last slot may be different
  CellPtr processCoordinateControlPacket(CellPtr pmsgIn) {
    CoordinateSuperSlotPacket *pcsspIn = 
      (CoordinateSuperSlotPacket *)(pmsgIn->data);

    if (pcsspIn->maOther == TOS_LOCAL_ADDRESS)
      {
	if (((pcsspIn->nMyLastSuperSlot) >= nMyFirstSlot) &&
	    ((pcsspIn->nMyFirstSuperSlot) <= nMyLastSuperSlot))
	  {
	    if ((pcsspIn->nMyFirstSuperSlot) <= nMyFirstSuperSlot)
	      {
		// user the latter part
		nMyFirstSuperSlot = pcsspIn->nMyLastSuperSlot + 1;
	      } // user the latter part
	    else
	      {
		// Use the fore part
		nMyLastSuperSlot = pcsspIn->nMyFirstSuperSlot - 1;
	      } // else use the latter part
	  } // If overlapping

	if (nMyFirstSuperSlot > nMyLastSuperSlot)
	  {
	    // I have no super slot to use so I need to allocate one
	    nMyLastSuperSlot = nMyFirstSuperSlot;
	  }

	dbg(DBG_AM, "PRIME:processCoordinateControlPacket: %d - %d\n",
	    nMyFirstSuperSlot, nMyLastSuperSlot);

      } // if I am maOther

    return pmsgIn;
  } // processCoordinateControlPacket

  CellPtr processControlPacket(CellPtr pmsgIn) {
    CellPtr pmsgR;
    ControlHeader *pchHeader = (ControlHeader *)pmsgIn->data;
    
    switch(pchHeader->cptType)
      {
      case PKT_CONTROL_SYNC:
	pmsgR = processSyncControlPacket(pmsgIn);
	break;

      case PKT_CONTROL_REPLY_INVITATION:
	pmsgR = processReplyInvitationControlPacket(pmsgIn);
	break;

      case PKT_CONTROL_COORDINATE:
	pmsgR = processCoordinateControlPacket(pmsgIn);
	break;

      case PKT_CONTROL_WHISPER:
	pmsgR = processWhisperControlPacket(pmsgIn);
	break;

      case PKT_CONTROL_INVITE_INTERFERENCE:
	pmsgR = processInviteInterferenceControlPacket(pmsgIn);
	break;

      default:
	pmsgR = pmsgIn;
	break;
      }
    return pmsgR;
  } // processControlPacket

  // Handle the event of the reception of an incoming message
  TOS_MsgPtr received(TOS_MsgPtr packet)  __attribute__ ((C, spontaneous)) {
    CellPtr pmsgR;

    // call Leds.greenToggle();
    cMacState = 0;

    /* uint16_t nTime =  call RadioTiming.currentTime(),
    // ///////  n = call RadioTiming.currentTime();

    //////// printf("***** t1 %x/t2 %x ** %d:%d\n", nTime, n, TOS_LOCAL_ADDRESS, nTime - packet->time-nTime);*/

    dbg(DBG_AM, 
	"PRIME: received at tick %lx, AM_address = %hx, %hhx\n", 
	ticPrime, packet->addr, packet->type);

#ifdef DBG_DUMP_MSG
    dumpPacket(packet);
#endif

#ifdef ICE_DBG
    // debug
    //call AM_DBG_SEND3("A", packet->addr, ticPrime);
#endif   
 
    KNOCKREC0(0xeeee);

    if (!(pmsgR = processPacket((CellPtr)packet)))
      {
	dbg(DBG_AM, "PRIME:received@%lx: got 0 after processing\n",
	    ticPrime);
      }

    // LEAVE;

    return 0;
  } // received

  // default do-nothing message receive handler
  default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
    return msg;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr packet) {
    TOS_MsgPtr pmsgR;

    KNOCK(packet, 0x3304);

    pmsgR = received(packet);

    LEAVE;

    return pmsgR;
  }

  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr packet) {
    TOS_MsgPtr pmsgR;

    KNOCK(packet, 0x3306);

    pmsgR = received(packet);

    LEAVE;

    return pmsgR;
  } // RadioReceive.receive

  void showLeds(long l)
    {
      if (l & 1)
	{
	  TOSH_CLR_RED_LED_PIN();
	}
      else
	{
	  TOSH_SET_RED_LED_PIN();
	}
      
      if (l & 2)
	{
	  TOSH_CLR_GREEN_LED_PIN();
	}
      else
	{
	  TOSH_SET_GREEN_LED_PIN();
	}
      
      if (l & 4)
	{
	  TOSH_CLR_YELLOW_LED_PIN();
	}
      else
	{
	  TOSH_SET_YELLOW_LED_PIN();
	}
    } // showLeds

  /*
    event result_t ChannelMon.startSymDetect()
    {
    dbg(DBG_AM, "PRIME: start sym detected %lx\n", ticPrime);
    // unprint4(ticPrime, ticNextStart, cDlState, 0x59000000);
    ticLastStartSym = ticPrime;

    return SUCCESS;
    }

    event result_t ChannelMon.idleDetect()
    {
    return SUCCESS;
    }
  */
}
