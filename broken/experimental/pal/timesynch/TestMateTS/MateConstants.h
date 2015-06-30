#ifndef BOMBILLA_CONSTANTS_H_INCLUDED
#define BOMBILLA_CONSTANTS_H_INCLUDED

typedef enum {
  MATE_OPTION_FORWARD     = 0x80,
  MATE_OPTION_FORCE       = 0x40,
  MATE_OPTION_MASK        = 0x3f,
} MateCapsuleOptions;

typedef enum {
  MHOplaceholder,
} MateHandlerOptions;

typedef enum {
  MATE_CONTEXT_GLOBALTRIGGER	 = 3,
  MATE_CONTEXT_TRIGGER	 = unique("MateContextID"),
  MATE_CONTEXT_GLOBALTIMER0	 = 17,
  MATE_CONTEXT_TIMER0	 = unique("MateContextID"),
  MATE_CONTEXT_GLOBALTIMER1	 = 16,
  MATE_CONTEXT_TIMER1	 = unique("MateContextID"),
  MATE_CONTEXT_GLOBALONCE	 = 2,
  MATE_CONTEXT_ONCE	 = unique("MateContextID"),
  MATE_CONTEXT_GLOBALREBOOT	 = 1,
  MATE_CONTEXT_REBOOT	 = unique("MateContextID"),
  MATE_CONTEXT_GLOBALBROADCAST	 = 32,
  MATE_CONTEXT_BROADCAST	 = unique("MateContextID"),
  MATE_CONTEXT_NUM	 = unique("MateContextID"),
  MATE_CONTEXT_INVALID = 255
} MateContextID;
typedef enum {
  MATE_HANDLER_GLOBAL_TRIGGER	 = 3,
  MATE_HANDLER_TRIGGER	 = unique("MateHandlerID"),
  MATE_HANDLER_GLOBAL_TIMER0	 = 17,
  MATE_HANDLER_TIMER0	 = unique("MateHandlerID"),
  MATE_HANDLER_GLOBAL_TIMER1	 = 16,
  MATE_HANDLER_TIMER1	 = unique("MateHandlerID"),
  MATE_HANDLER_GLOBAL_ONCE	 = 2,
  MATE_HANDLER_ONCE	 = unique("MateHandlerID"),
  MATE_HANDLER_GLOBAL_REBOOT	 = 1,
  MATE_HANDLER_REBOOT	 = unique("MateHandlerID"),
  MATE_HANDLER_GLOBAL_BROADCAST	 = 32,
  MATE_HANDLER_BROADCAST	 = unique("MateHandlerID"),
  MATE_HANDLER_NUM	 = unique("MateHandlerID"),
  MATE_HANDLER_INVALID = 255
} MateHandlerID;

typedef enum {
  MATE_CAPSULE_TRIGGER	 = unique("MateCapsuleID"),
  MATE_CAPSULE_TIMER0	 = unique("MateCapsuleID"),
  MATE_CAPSULE_TIMER1	 = unique("MateCapsuleID"),
  MATE_CAPSULE_ONCE	 = unique("MateCapsuleID"),
  MATE_CAPSULE_REBOOT	 = unique("MateCapsuleID"),
  MATE_CAPSULE_BROADCAST	 = unique("MateCapsuleID"),
  MATE_CAPSULE_NUM	 = unique("MateCapsuleID"),
  MATE_CAPSULE_INVALID = 255
} MateCapsuleID;

enum {
  MATE_CALLDEPTH    = 8,
  MATE_OPDEPTH      = 8,
  MATE_LOCK_COUNT   = uniqueCount("MateLock"),
  MATE_BUF_LEN      = 10,
  MATE_CAPSULE_SIZE = 128,
  MATE_HANDLER_SIZE = 128,
  MATE_CPU_QUANTUM  = 4,
  MATE_CPU_SLICE    = 5,
} MateSizeConstants;

typedef enum {
  MATE_TYPE_NONE      = 0,
  MATE_TYPE_BUFFER    = 1,
  MATE_TYPE_INTEGER   = 32,
  MATE_TYPE_MSBPHOTO  = 48,
  MATE_TYPE_MSBTEMP   = 49,
  MATE_TYPE_MSBMIC    = 50,
  MATE_TYPE_MSBMAGX   = 51,
  MATE_TYPE_MSBMAGY   = 52,
  MATE_TYPE_MSBACCELX = 53,
  MATE_TYPE_MSBACCELY = 54,
  MATE_TYPE_THUM      = 55,
  MATE_TYPE_TTEMP     = 56,
  MATE_TYPE_TPAR      = 57,
  MATE_TYPE_TTSR      = 58,
  MATE_TYPE_END       = 59
} MateDataType;

typedef enum {
  MATE_STATE_HALT,
  MATE_STATE_WAITING,
  MATE_STATE_READY,
  MATE_STATE_RUN,
  MATE_STATE_BLOCKED,
} MateContextState;

typedef enum {
  MATE_ERROR_TRIGGERED,
  MATE_ERROR_INVALID_RUNNABLE,
  MATE_ERROR_STACK_OVERFLOW,
  MATE_ERROR_STACK_UNDERFLOW,
  MATE_ERROR_BUFFER_OVERFLOW,
  MATE_ERROR_BUFFER_UNDERFLOW,
  MATE_ERROR_INDEX_OUT_OF_BOUNDS,
  MATE_ERROR_INSTRUCTION_RUNOFF,
  MATE_ERROR_LOCK_INVALID,
  MATE_ERROR_LOCK_STEAL,
  MATE_ERROR_UNLOCK_INVALID,
  MATE_ERROR_QUEUE_ENQUEUE,
  MATE_ERROR_QUEUE_DEQUEUE,
  MATE_ERROR_QUEUE_REMOVE,
  MATE_ERROR_QUEUE_INVALID,
  MATE_ERROR_RSTACK_OVERFLOW,
  MATE_ERROR_RSTACK_UNDERFLOW,
  MATE_ERROR_INVALID_ACCESS,
  MATE_ERROR_TYPE_CHECK,
  MATE_ERROR_INVALID_TYPE,
  MATE_ERROR_INVALID_LOCK,
  MATE_ERROR_INVALID_INSTRUCTION,
  MATE_ERROR_INVALID_SENSOR,
  MATE_ERROR_INVALID_HANDLER,
  MATE_ERROR_ARITHMETIC,
  MATE_ERROR_SENSOR_FAIL,
} MateErrorCode;

enum {
  AM_MATEUARTMSG    = 0x19,
  AM_MATEBCASTMSG   = 0x1a,
  AM_MATEROUTEMSG         = 0x1b,
  AM_MATEVERSIONMSG       = 0x1c,
  AM_MATEVERSIONREQUESTMSG= 0x22,
  AM_MATEERRORMSG         = 0x1d,
  AM_MATECAPSULEMSG       = 0x1e,
  AM_MATEPACKETMSG        = 0x1f,
  AM_MATECAPSULECHUNKMSG  = 0x20,
  AM_MATECAPSULESTATUSMSG = 0x21,
};

typedef enum { // instruction set
  OP_HALT = 	0x0,
  OP_BCOPY = 	0x1,
  OP_ADD = 	0x2,
  OP_SUB = 	0x3,
  OP_LAND = 	0x4,
  OP_LOR = 	0x5,
  OP_OR = 	0x6,
  OP_AND = 	0x7,
  OP_NOT = 	0x8,
  OP_LNOT = 	0x9,
  OP_DIV = 	0xa,
  OP_BTAIL = 	0xb,
  OP_EQV = 	0xc,
  OP_EXP = 	0xd,
  OP_IMP = 	0xe,
  OP_LXOR = 	0xf,
  OP_2PUSHC10 = 	0x10,
  OP_2JUMPS10 = 	0x14,
  OP_GETLOCAL3 = 	0x18,
  OP_SETLOCAL3 = 	0x20,
  OP_UNLOCK = 	0x28,
  OP_PUNLOCK = 	0x29,
  OP_BPUSH3 = 	0x2a,
  OP_GETVAR4 = 	0x32,
  OP_SETVAR4 = 	0x42,
  OP_PUSHC6 = 	0x52,
  OP_MOD = 	0x92,
  OP_MUL = 	0x93,
  OP_BREAD = 	0x94,
  OP_BWRITE = 	0x95,
  OP_POP = 	0x96,
  OP_EQ = 	0x97,
  OP_GTE = 	0x98,
  OP_GT = 	0x99,
  OP_LT = 	0x9a,
  OP_LTE = 	0x9b,
  OP_NEQ = 	0x9c,
  OP_COPY = 	0x9d,
  OP_INV = 	0x9e,
  OP_SOFF = 	0x9f,
  OP_SON = 	0xa0,
  OP_LIGHT = 	0xa1,
  OP_TEMP = 	0xa2,
  OP_MIC = 	0xa3,
  OP_ACCELX = 	0xa4,
  OP_ACCELY = 	0xa5,
  OP_MAGX = 	0xa6,
  OP_MAGY = 	0xa7,
  OP_BCLEAR = 	0xa8,
  OP_BFULL = 	0xa9,
  OP_BSIZE = 	0xaa,
  OP_BUFSORTA = 	0xab,
  OP_BUFSORTD = 	0xac,
  OP_EQTYPE = 	0xad,
  OP_ERR = 	0xae,
  OP_ID = 	0xaf,
  OP_INT = 	0xb0,
  OP_LED = 	0xb1,
  OP_RAND = 	0xb2,
  OP_SEND = 	0xb3,
  OP_SLEEP = 	0xb4,
  OP_UART = 	0xb5,
  OP_TRIGGER = 	0xb6,
  OP_TRIGGERBUF = 	0xb7,
  OP_SETTIMER0 = 	0xb8,
  OP_SETTIMER1 = 	0xb9,
  OP_BCAST = 	0xba,
  OP_BCASTBUF = 	0xbb,
} MateInstruction;

typedef enum { // Function identifiers
  MFIplaceholder,
} MateFunctionID;

/*
 * MVirus uses the Trickle algorithm for code propagation and maintenance.
 * A full description and evaluation of the algorithm can be found in
 *
 * Philip Levis, Neil Patel, David Culler, and Scott Shenker.
 * "Trickle: A Self-Regulating Algorithm for Code Propagation and Maintenance
 * in Wireless Sensor Networks." In Proceedings of the First USENIX/ACM
 * Symposium on Networked Systems Design and Implementation (NSDI 2004).
 *
 * A copy of the paper can be downloaded from Phil Levis' web site:
 *        http://www.cs.berkeley.edu/~pal/
 *
 * A brief description of the algorithm can be found in the comments
 * at the head of MVirus.nc.
 *
 */

typedef enum {
  /* These first two constants define the granularity at which t values
     are calculated (in ms). Version vectors and capsules have separate
     timers, as version timers decay (lengthen) while capsules timers
     are constant, as they are not a continuous process.*/
  MVIRUS_VERSION_TIMER = 100,           // The units of time (ms)
  MVIRUS_CAPSULE_TIMER = 100,           // The units of time (ms)

  /* These constants define how many times a capsule is transmitted,
     the timer interval for Trickle suppression, and the redundancy constant
     k. Due to inherent loss, having a repeat > 1 is preferrable, although
     it should be small. It's better to broadcast the data twice rather
     than require another metadata announcement to trigger another
     transmission. It's not clear whether REDUNDANCY should be > or = to
     REPEAT. In either case, both constants should be small (e.g, 2-4). */
  
  MVIRUS_CAPSULE_REPEAT = 2,            // How many times to repeat a capsule
  MVIRUS_CAPSULE_TAU = 10,              // Capsules have a fixed tau
  MVIRUS_CAPSULE_REDUNDANCY = 2,        // Capsule redundancy (suppression pt.)

  /* These constants define the minimum and maximum tau values for
     version vector exchange, as well as the version vector redundancy
     constant k. Note that the tau values are in terms of multiples
     of the TIMER value above (e.g., a MIN of 10 and a TIMER of 100
     means a MIN of 1000 ms, or one second). */
  MVIRUS_VERSION_TAU_MIN = 10,          // Version scaling tau minimum
  MVIRUS_VERSION_TAU_MAX = 600,         // Version scaling tau maximum
  MVIRUS_VERSION_REDUNDANCY = 1,        // Version redundancy (suppression pt.)
  
  /* These constants are all for sending data larger than a single
     packet; they define the size of a program chunk, bitmasks, etc.*/
  MVIRUS_CHUNK_HEADER_SIZE = 8,
  MVIRUS_CHUNK_SIZE = TOSH_DATA_LENGTH - MVIRUS_CHUNK_HEADER_SIZE,
  MVIRUS_BITMASK_ENTRIES = ((MATE_CAPSULE_SIZE + MVIRUS_CHUNK_SIZE - 1) / MVIRUS_CHUNK_SIZE),
  MVIRUS_BITMASK_SIZE = (MVIRUS_BITMASK_ENTRIES + 7) / 8,
} MVirusConstants;

#endif
