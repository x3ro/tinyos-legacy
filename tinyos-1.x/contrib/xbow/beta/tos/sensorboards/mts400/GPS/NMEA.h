/**
 *
 * This code is part of the NSF-ITR funded 
 * FireBug project:
 * @url http://firebug.sourceforge.net
 *
 * @author David M. Doolin
 *
 * $Id: NMEA.h,v 1.1 2005/03/04 10:16:36 husq Exp $
 *
 */

#ifndef FB_NMEA_H
#define FB_NMEA_H

#include <inttypes.h>

/** @brief NMEA message parser which uses a lot of macros
 * and lower-level operations to extract data from the
 * character string comprising NMEA messages returned
 * from a GPS device.
 *
 * @todo RMC parser: Finish, check the test.
 *
 * @todo VTG parser, need to fix the test and get better
 *  documentation for valid vtg type sentences because the 
 *  example provided in the LeadTek manual is not very good.
 *
 * @todo Move all the test strings to static const at the
 *  head of the nmea_parse_test file so that the checksums
 *  can all be verified.
 *
 * @todo Construct a framework for NMEA input messages used
 *  to control the GPS device.
 */

/** For various reasons, these have been defined in several
 * different places.  They should be defined either here,
 * or in files specific to the particular GGA sentence under
 * consideration.
 */

#ifndef NMEA_EXTRACTION_MACROS
#define NMEA_EXTRACTION_MACROS
#define extract_fix_quality_m(data)  (data[0]-'0')
#define extract_num_sats_m(data)     (10*(data[0]-'0') + (data[1]-'0'))
#define extract_hours_m(data)        (10*(data[0]-'0') + (data[1]-'0'))
#define extract_minutes_m(data)      (10*(data[2]-'0') + (data[3]-'0'))
#define extract_dec_sec_m(data)      (10*(data[4]-'0') +  (data[5]-'0') + 0.1*(data[7]-'0') \
                                      + 0.01*(data[8]-'0')                                  \
				      + 0.001*(data[9]-'0'))
#define extract_Lat_deg_m(data)      (10*(data[0]-'0') + (data[1]-'0'))
#define extract_Lat_dec_min_m(data)  (10*(data[2]-'0') +  (data[3]-'0') + 0.1*(data[5]-'0') \
                                      + 0.01*(data[6]-'0') + 0.001*(data[7]-'0') + 0.0001*(data[8]-'0'))
#define extract_Long_deg_m(data)     (100*(data[0]-'0') + 10*(data[1]-'0') + (data[2]-'0'))
#define extract_Long_dec_min_m(data) (10*(data[3]-'0') +  (data[4]-'0') + 0.1*(data[6]-'0') \
				      + 0.01*(data[7]-'0') + 0.001*(data[8]-'0') + 0.0001*(data[9]-'0'))
#endif

/** @brief These are the most common NMEA-0183 sentences
 * all of which are available on the LeadTek 9546.
 * Other sentences can be added very easily.
 */
enum {
  GGA,
  GSV,
  GLL,
  GSA,
  RMC,
  VTG,
  MSS,
  UNKNOWN
};


/** @brief Helpful macros, useful when only one or two particular
 * messages need to be extracted.  If every NMEA sentence needs to
 * be processed, use the dispatch table instead of writing a
 * big if-else statement.  White space is suppressed to keep
 * everything on one line.
 */
#define is_gga_string_m(ns) ((ns[3]=='G')&&(ns[4]=='G')&&(ns[5]=='A'))
#define is_gsa_string_m(ns) ((ns[3]=='G')&&(ns[4]=='S')&&(ns[5]=='A'))
#define is_gsv_string_m(ns) ((ns[3]=='G')&&(ns[4]=='S')&&(ns[5]=='V'))
#define is_gll_string_m(ns) ((ns[3]=='G')&&(ns[4]=='L')&&(ns[5]=='L'))
#define is_rmc_string_m(ns) ((ns[3]=='R')&&(ns[4]=='M')&&(ns[5]=='C'))
#define is_vtg_string_m(ns) ((ns[3]=='V')&&(ns[4]=='T')&&(ns[5]=='G'))
#define is_mss_string_m(ns) ((ns[3]=='M')&&(ns[4]=='S')&&(ns[5]=='S'))

typedef struct _nmea_data NMEA_Data;
// 0 length for using in TinyOS interface 
// definitions, general type checking, etc.
// Members may be added later.
struct _nmea_data {
};


/** @brief The data encapsulated in an NMEA sentence
 * needs to be changed from character format to
 * appropriate type: int or float for time and 
 * lat/long positions.  For TOS applications, 
 * incomplete types are rarely used, struct members
 * are accessed directly.  For applications with
 * much faster cpu and more ram, these definitions
 * could be changed into incomplete types, and the
 * appropriate accessor methods written for support.
 * Currently, the mig message generator requires
 * messages to be defined as below to generate the
 * correct Java code. 
 */
typedef struct gga_data {
  NMEA_Data nd;

  uint8_t  hours;
  uint8_t  minutes;
  uint8_t  Lat_deg;
  uint8_t  Long_deg;
  float dec_sec; 
  float Lat_dec_min; 
  float Long_dec_min;
  uint8_t  NSEWind; 
  uint8_t  fixQuality; 
  uint8_t  num_sats;           
} GGA_Data;


typedef struct gll_data {
  NMEA_Data nd;

  uint8_t  Lat_deg;
  uint8_t  Long_deg;
  uint8_t  hours;
  uint8_t  minutes;
  uint32_t Long_dec_min;
  uint32_t Lat_dec_min;
  uint32_t dec_sec;
  uint8_t  NSEWind; 
  char status;
} GLL_Data;


typedef struct gsa_data {
  NMEA_Data nd;
  uint8_t sat_used[12];
  // These may be able to be stuffed into uint16_t,
  // depending on the precision the GPS unit reports.
  // Ask LeadTek or SiRF about this, but use float for
  // to get the code running.
  float PDOP;
  float HDOP;
  float VDOP;
  char mode1;
  uint8_t mode2;

} GSA_Data;


typedef struct _gsv_channel {

  uint8_t sat_id;
  uint8_t elevation;
  uint16_t azimuth;
  uint8_t SNR;
} gsv_channel;

typedef struct gsv_data {
  NMEA_Data nd;

  uint8_t num_messages;
  uint8_t message_number;
  uint8_t satellites_in_view;

  gsv_channel channel[4];

} GSV_Data;

typedef struct rmc_data {
  NMEA_Data nd;
} RMC_Data;

typedef struct vtg_data {
  NMEA_Data nd;

  float course_true;
  float course_mag;
  float speed_knots;
  float speed_kph;
  
} VTG_Data;

typedef struct mss_data {
  NMEA_Data nd;

  uint8_t signal_strength;
  uint8_t SNR;
  uint16_t bit_rate;
  float beacon_freq;

} MSS_Data;



#endif /* FB_NMEA_H */
