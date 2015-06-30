/*
 * host-mote.h: structures and constants for communication between
 * host and MoteNIC
 *
 * author: jelson
 *
 * $Id: host_mote_macros.h,v 1.1.1.2 2004/03/06 03:01:06 mturon Exp $
 */

#ifndef __HOST_MOTE_MACROS_H__
#define __HOST_MOTE_MACROS_H__

//#define DATA_LENGTH_GUESS 200
#define DATA_LENGTH_GUESS 27

#ifdef HOST_MOTE_DATA_LENGTH
# if (HOST_MOTE_DATA_LENGTH != DATA_LENGTH_GUESS)
#  error FIX DATA_LENGTH_GUESS in host-mote.h to match HOST_MOTE_DATA_LENGTH in MSG.h
# endif
#else
#define HOST_MOTE_DATA_LENGTH DATA_LENGTH_GUESS
#endif // HOST_MOTE_DATA_LENGTH

// NOTE: this was a #define which was moved here and changed into enum because
// the definition of structs (esp. array sizes in them) required them.
// And NesC discards #defines

#ifdef MAX_PKT_LEN
enum {
  HOSTMOTE_MAX_DATA_PAYLOAD = (int16_t)(MAX_PKT_LEN * 2)
};
#else
enum {
  HOSTMOTE_MAX_DATA_PAYLOAD =  (int16_t)(HOST_MOTE_DATA_LENGTH * 2)
};
#endif // MAX_PKT_LEN
 
#define MAX_SENSOR_READINGS 32

/* constants for framing */
#define HOSTMOTE_FRAME_1 0x74
#define HOSTMOTE_FRAME_2 0x19

/* constants for opnum */
#define HOSTMOTE_NOOP  0x0
#define HOSTMOTE_RST   0x1   /* RESET */
#define HOSTMOTE_NIC   0x2   /* Mote-NIC Type */
#define HOSTMOTE_SENS  0x3   /* Sensor/Sampling Access Type */
#define HOSTMOTE_CONF  0x4   /* Configuration Type */
#define HOSTMOTE_SLEEP 0x5   /* sleep the mote */

/* subop CONF */
#define CONF_SYNC   0x1
#define CONF_STAT   0x2
#define CONF_CONF   0x3

/* subop NIC */
#define NIC_DHN     0x1
#define NIC_DNH     0x2
#define NIC_RDHN    0x3
#define NIC_CDHN    0x4
#define NIC_FDHN    0x5

/* subop SENS */
#define SENS_CONF   0x1
#define SENS_REPORT 0x2
#define SENS_DATA   0x3

/* accessor functions for fields of the structure */

/* construct a value from MSB and LSB parts */
#define HOSTMOTE_MSBLSB(msb, lsb)  ((((int)msb) << 8) | (lsb))

/* set MSB and LSB components based on a desired value */
#define HOSTMOTE_SETMSBLSB(value, msb, lsb) do { \
  msb = (((value) >> 8) & 0xFF); \
  lsb = ((value) & 0xFF); \
} while (0)

#define HOSTMOTE_SET_FRAME(header) do { \
  (header)->frame1 = HOSTMOTE_FRAME_1; \
  (header)->frame2 = HOSTMOTE_FRAME_2; \
} while (0)


#define HOSTMOTE_SUBOP(header)      ((header)->subop)
#define HOSTMOTE_SET_SUBOP(value, header) do { \
  (header)->subop = value; \
} while (0)

#define HOSTMOTE_OPNUM(header)      ((header)->opnum)
#define HOSTMOTE_SET_OPNUM(value, header) do { \
  (header)->opnum = value; \
} while (0)

#define HOSTMOTE_SET_OP(value_op, value_sub, header) do { \
  (header)->opnum = value_op; \
  (header)->subop = value_sub; \
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


#define CONF_SET_SADDR (1 << 0)
#define CONF_SET_DADDR (1 << 1)
#define CONF_SET_GROUP (1 << 2)
#define CONF_SET_POT   (1 << 3)
#define CONF_SET_CLOCK (1 << 4)
#define CONF_SET_BOARD (1 << 5)

// SMAC substitues SET_ADDR and SET_GROUP with SET_SRC and SET_DST
#define CONF_SET_SRC   (1 << 0)
#define CONF_SET_DST   (1 << 1)

/* board types */
#define NONE	0x0
#define BASIC	0x1
#define MICASB	0x2
#define MICAWB	0x3


/* ************** SENS protocol header ***********/

/* undoing pin remap error on mica board */
/* mica pin numbering on rene adc0-7 on mica adc7-0 */
/* hacking to work with mica for now */
#ifdef MICA
#define SENS_LIGHT   6
#define SENS_TEMP    5
#define SENS_THERMAL 4
#else
#define SENS_LIGHT   1
#define SENS_TEMP    2
#define SENS_THERMAL 3
#endif

/* letting the user keep pin mappings straight */
#define ADC0	     0x0
#define ADC1	     0x1
#define ADC2	     0x2
#define ADC3	     0x3
#define ADC4	     0x4
#define ADC5	     0x5
#define ADC6	     0x6
#define ADC7	     0x7



#define HOSTMOTE_SET_SENS_LIGHT(data) do { \
  (data)->value1=LIGHT_FRAME_1; \
  (data)->value2=LIGHT_FRAME_2; \
} while (0)

#define HOSTMOTE_SET_SENS_TEMP(data) do { \
    (data)->value1=TEMP_FRAME_1; \
    (data)->value2=TEMP_FRAME_2; \
} while (0)

#define HOSTMOTE_SET_POT_GET(data) do { \
    (data)->value1=POT_GET;\
} while (0)

#define HOSTMOTE_SET_POT_SET(data) do { \
    (data)->value1=POT_SET;\
} while(0)


#define LIGHT_FRAME_1 0x6C
#define LIGHT_FRAME_2 0x69
#define TEMP_FRAME_1  0x74
#define TEMP_FRAME_2  0x65
#define POT_GET     0x47
#define POT_SET     0x53
#define POT_FRAME   0xF0    

#endif //ifndef __HOST_MOTE_MACROS_H__









