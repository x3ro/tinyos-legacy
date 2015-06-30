/*
 * host-mote.h: structures and constants for communication between
 * host and MoteNIC
 *
 * author: jelson
 *
 * $Id: host-mote.h,v 1.1.1.1 2001/09/26 21:55:07 szewczyk Exp $
 */


#define DATA_LENGTH_GUESS 30

#ifdef DATA_LENGTH
# if (DATA_LENGTH != DATA_LENGTH_GUESS)
#  error FIX DATA_LENGTH_GUESS in host-mote.h to match DATA_LENGTH in MSG.h
# endif
#else
# define DATA_LENGTH DATA_LENGTH_GUESS
#endif

typedef struct {
  unsigned char frame1;
  unsigned char frame2;
  unsigned char flags_opnum;  /* combined field: see accessor macros */
  unsigned char datalen_msb;
  unsigned char datalen_lsb;
} hostmote_header;

typedef struct {
  unsigned char packetlen_msb;
  unsigned char packetlen_lsb;
  unsigned char qlen_hint_msb;
  unsigned char qlen_hint_lsb;
} hostmote_rdhn;

/* For the sensor request part */
typedef struct {
  unsigned char value1;
  unsigned char value2;
} hostmote_sens;

/* constants for opnum */
#define HOSTMOTE_NOOP 0x0
#define HOSTMOTE_RST  0x1
#define HOSTMOTE_DHN  0x2
#define HOSTMOTE_DNH  0x3
#define HOSTMOTE_RDHN 0x4
#define HOSTMOTE_CDHN 0x5
#define HOSTMOTE_FDHN 0x6
#define HOSTMOTE_SENS 0x7


/* accessor functions for fields of the structure */

/* construct a value from MSB and LSB parts */
#define HOSTMOTE_MSBLSB(msb, lsb)  ((((int)msb) << 8) | (lsb))

/* set MSB and LSB components based on a desired value */
#define HOSTMOTE_SETMSBLSB(value, msb, lsb) do { \
  msb = (((value) >> 8) & 0xFF); \
  lsb = ((value) & 0xFF); \
} while (0)

#define MOTENIC_FRAME_1 0x74
#define MOTENIC_FRAME_2 0x19

#define LIGHT_FRAME_1 0x6C
#define LIGHT_FRAME_2 0x69
#define TEMP_FRAME_1  0x74
#define TEMP_FRAME_2  0x65

#define HOSTMOTE_SET_FRAME(header) do { \
  (header)->frame1 = MOTENIC_FRAME_1; \
  (header)->frame2 = MOTENIC_FRAME_2; \
} while (0)

#define HOSTMOTE_FLAGS(header)     ((((header)->flags_opnum) & 0xF0) >> 4)
#define HOSTMOTE_SET_FLAGS(value, header) do { \
  (header)->flags_opnum &= 0x0F; \
  (header)->flags_opnum |= (((value) & 0x0F) << 4); \
} while (0)


#define HOSTMOTE_OPNUM(header)      (((header)->flags_opnum) & 0x0F)
#define HOSTMOTE_SET_OPNUM(value, header) do { \
  (header)->flags_opnum &= 0xF0; \
  (header)->flags_opnum |= ((value) & 0x0F); \
} while (0)

#define HOSTMOTE_DATALEN(header) \
  HOSTMOTE_MSBLSB((header)->datalen_msb, (header)->datalen_lsb)
#define HOSTMOTE_SET_DATALEN(value, header) \
  HOSTMOTE_SETMSBLSB(value, (header)->datalen_msb, (header)->datalen_lsb)

#define HOSTMOTE_RDHN_LEN(data) \
  HOSTMOTE_MSBLSB((data)->packetlen_msb, (data)->packetlen_lsb)
#define HOSTMOTE_SET_RDHN_LEN(value, data) \
  HOSTMOTE_SETMSBLSB(value, (data)->packetlen_msb, (data)->packetlen_lsb)

#define HOSTMOTE_RDHN_HINT(data) \
  HOSTMOTE_MSBLSB((data)->qlen_hint_msb, (data)->qlen_hint_lsb)
#define HOSTMOTE_SET_RDHN_HINT(value, data) \
  HOSTMOTE_SETMSBLSB(value, (data)->qlen_hint_msb, (data)->qlen_hint_lsb)

#define HOSTMOTE_SET_SENS_LIGHT(data) do { \
  (data)->value1=LIGHT_FRAME_1; \
  (data)->value2=LIGHT_FRAME_2; \
} while (0)

#define HOSTMOTE_SET_SENS_TEMP(data) do { \
    (data)->value1=TEMP_FRAME_1; \
    (data)->value2=TEMP_FRAME_2; \
} while (0)


/***************** Structures used in the TinyOS Code *********************/

/*
 * This structure is used to communicate between Host and Mote.  It
 * contains a header followed by space for data.
 *
 * Note that this is not the same as a TOS_Msg, which is the structure
 * used mote-to-mote.
 */

#define HOSTMOTE_MAX_DATA_PAYLOAD  (DATA_LENGTH * 2)
struct HostMote_Msg_struct {
  hostmote_header header;
  char data[HOSTMOTE_MAX_DATA_PAYLOAD];
};

typedef struct HostMote_Msg_struct HostMote_Msg;
typedef HostMote_Msg *HostMote_MsgPtr;

typedef hostmote_sens *Sens_MsgPtr;
