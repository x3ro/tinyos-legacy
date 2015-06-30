#ifndef BOMBILLA_CONSTANTS_H_INCLUDED
#define BOMBILLA_CONSTANTS_H_INCLUDED

typedef enum {
BOMB_OPTION_FORWARD     = 0x80,
BOMB_OPTION_FORCE       = 0x40,
BOMB_OPTION_MASK        = 0x3f,
} BombillaCapsuleOption;

typedef enum {
BOMB_CONTEXT_TIMER1	 = unique("BombillaContextConstant"),
BOMB_CONTEXT_ONCE	 = unique("BombillaContextConstant"),
BOMB_CONTEXT_NUM	 = unique("BombillaContextConstant"),
BOMB_CONTEXT_INVALID = 255
} BombillaContextType;
typedef enum {
BOMB_CAPSULE_TIMER1	 = unique("BombillaCapsuleConstant"),
BOMB_CAPSULE_ONCE	 = unique("BombillaCapsuleConstant"),
BOMB_CAPSULE_NUM	 = unique("BombillaCapsuleConstant"),
BOMB_CAPSULE_INVALID = 255
} BombillaCapsuleType;

enum {
BOMB_CALLDEPTH    = 8,
BOMB_OPDEPTH      = 16,
BOMB_HEAPSIZE     = uniqueCount("BombillaLock"),
BOMB_MAX_PARALLEL = 4,
BOMB_NUM_YIELDS   = 4,
BOMB_HEADERSIZES  = 3,
BOMB_HEADERSIZE   = 6,
BOMB_BUF_LEN      = 10,
BOMB_PGMSIZE      = 24,
BOMB_BUF_NUM      = 2
} BombillaSizeConstants;

typedef enum {
BOMB_DATA_NONE    = unique("BombillaSensorType"),
BOMB_DATA_VALUE   = unique("BombillaSensorType"),
BOMB_DATA_PHOTO   = unique("BombillaSensorType"),
BOMB_DATA_TEMP    = unique("BombillaSensorType"),
BOMB_DATA_MIC     = unique("BombillaSensorType"),
BOMB_DATA_MAGX    = unique("BombillaSensorType"),
BOMB_DATA_MAGY    = unique("BombillaSensorType"),
BOMB_DATA_ACCELX  = unique("BombillaSensorType"),
BOMB_DATA_ACCELY  = unique("BombillaSensorType"),
BOMB_DATA_END     = unique("BombillaSensorType")
} BombillaSensorType;

typedef enum {
BOMB_TYPE_INVALID = 0,
BOMB_TYPE_VALUE   = (1 << unique("BombillaDataType")),
BOMB_TYPE_BUFFER  = (1 << unique("BombillaDataType")),
BOMB_TYPE_SENSE   = (1 << unique("BombillaDataType"))
} BombillaDataType;

typedef enum {
BOMB_VAR_V = BOMB_TYPE_VALUE,
BOMB_VAR_B = BOMB_TYPE_BUFFER,
BOMB_VAR_S = BOMB_TYPE_SENSE,
BOMB_VAR_VB = BOMB_VAR_V | BOMB_VAR_B,
BOMB_VAR_VS = BOMB_VAR_V | BOMB_VAR_S,
BOMB_VAR_SB = BOMB_VAR_B | BOMB_VAR_S,
BOMB_VAR_VSB = BOMB_VAR_B | BOMB_VAR_S | BOMB_VAR_V,
BOMB_VAR_ALL = BOMB_VAR_B | BOMB_VAR_S | BOMB_VAR_V
} BombillaDataCondensed;

typedef enum {
BOMB_STATE_HALT        = unique("BombillaState"),
BOMB_STATE_SENDING     = unique("BombillaState"),
BOMB_STATE_LOG         = unique("BombillaState"),
BOMB_STATE_SENSE       = unique("BombillaState"),
BOMB_STATE_SEND_WAIT   = unique("BombillaState"),
BOMB_STATE_LOG_WAIT    = unique("BombillaState"),
BOMB_STATE_SENSE_WAIT  = unique("BombillaState"),
BOMB_STATE_LOCK_WAIT   = unique("BombillaState"),
BOMB_STATE_RESUMING    = unique("BombillaState"),
BOMB_STATE_RUN         = unique("BombillaState")
} BombillaContextState;

typedef enum {
BOMB_ERROR_TRIGGERED                =  unique("BombillaError"),
BOMB_ERROR_INVALID_RUNNABLE         =  unique("BombillaError"),
BOMB_ERROR_STACK_OVERFLOW           =  unique("BombillaError"),
BOMB_ERROR_STACK_UNDERFLOW          =  unique("BombillaError"),
BOMB_ERROR_BUFFER_OVERFLOW          =  unique("BombillaError"),
BOMB_ERROR_BUFFER_UNDERFLOW         =  unique("BombillaError"),
BOMB_ERROR_INDEX_OUT_OF_BOUNDS      =  unique("BombillaError"),
BOMB_ERROR_INSTRUCTION_RUNOFF       =  unique("BombillaError"),
BOMB_ERROR_LOCK_INVALID             =  unique("BombillaError"),
BOMB_ERROR_LOCK_STEAL               =  unique("BombillaError"),
BOMB_ERROR_UNLOCK_INVALID           = unique("BombillaError"),
BOMB_ERROR_QUEUE_ENQUEUE            = unique("BombillaError"),
BOMB_ERROR_QUEUE_DEQUEUE            = unique("BombillaError"),
BOMB_ERROR_QUEUE_REMOVE             = unique("BombillaError"),
BOMB_ERROR_QUEUE_INVALID            = unique("BombillaError"),
BOMB_ERROR_RSTACK_OVERFLOW          = unique("BombillaError"),
BOMB_ERROR_RSTACK_UNDERFLOW         = unique("BombillaError"),
BOMB_ERROR_INVALID_ACCESS           = unique("BombillaError"),
BOMB_ERROR_TYPE_CHECK               = unique("BombillaError"),
BOMB_ERROR_INVALID_TYPE             = unique("BombillaError"),
BOMB_ERROR_INVALID_LOCK             = unique("BombillaError"),
BOMB_ERROR_INVALID_INSTRUCTION      = unique("BombillaError"),
BOMB_ERROR_INVALID_SENSOR           = unique("BombillaError")
} BombillaErrorCode;

typedef enum {
BOMB_MAX_NET_ACTIVITY  = 64,
BOMB_PROPAGATE_TIMER   = 737,
BOMB_PROPAGATE_FACTOR  = 0x7f   // 127
} BombillaCapsulePropagateConstants;

typedef enum {
MOP_MASK    = 0xe0,
MCLASS_OP   = 0x40,
MARG_MASK   = 0x07,
MINSTR_MASK = 0xf8,
VOP_MASK    = 0xe0,
VCLASS_OP   = 0x60,
VARG_MASK   = 0x0f,
VINSTR_MASK = 0xf0,
JOP_MASK    = 0xc0,
JCLASS_OP   = 0x80,
JARG_MASK   = 0x1f,
JINSTR_MASK = 0xe0,
XOP_MASK    = 0xc0,
XCLASS_OP   = 0xc0,
XARG_MASK   = 0x3f,
XINSTR_MASK = 0xc0,
} BombillaInstructionMasks;

enum {
AM_BOMBILLAROUTEMSG   = 0x1b,
AM_BOMBILLAVERSIONMSG  = 0x1c,
AM_BOMBILLAERRORMSG    = 0x1d,
AM_BOMBILLACAPSULEMSG  = 0x1e,
AM_BOMBILLAPACKETMSG   = 0x1f
};

typedef enum {
// instruction set,
OPadd	= 0x0,
OPsub	= 0x1,
OPhalt	= 0x2,
OPland	= 0x3,
OPlor	= 0x4,
OPor	= 0x5,
OPand	= 0x6,
OPnot	= 0x7,
OPlnot	= 0x8,
OPdiv	= 0x9,
OPbtail	= 0xa,
OPeqv	= 0xb,
OPexp	= 0xc,
OPimp	= 0xd,
OPlxor	= 0xe,
OPmod	= 0xf,
OPmul	= 0x10,
OPbread	= 0x11,
OPbwrite	= 0x12,
OPpop	= 0x13,
OPeq	= 0x14,
OPgte	= 0x15,
OPgt	= 0x16,
OPlt	= 0x17,
OPlte	= 0x18,
OPneq	= 0x19,
OPcopy	= 0x1a,
OPinv	= 0x1b,
OPputled	= 0x1c,
OPbclear	= 0x1d,
OPcast	= 0x1e,
OPid	= 0x1f,
OPuart	= 0x20,
OPrand	= 0x21,
OProute	= 0x22,
OPbpush1	= 0x24,
OPsettimer1	= 0x26,
OP2pushc10	= 0x28,
OP2jumps10	= 0x2c,
OPgetlocal3	= 0x30,
OPsetlocal3	= 0x38,
OPgetvar4	= 0x40,
OPsetvar4	= 0x50,
OPpushc6	= 0x80
} BombillaInstruction;

#endif
