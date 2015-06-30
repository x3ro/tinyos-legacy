

/**
 * Module for parsing NMEA - 0183 sentences.
 *
 * This code is part of the NSF-ITR funded 
 * FireBug project:
 * @url http://firebug.sourceforge.net
 *
 * @author David M. Doolin
 *
 * $Id: NMEAM.nc,v 1.1 2004/08/31 22:15:20 doolin Exp $
 */

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
#define GGA_NS_m(foo)                    ((foo[28]=='N') ? 1 : 0)
#define GGA_EW_m(foo)                    ((foo[41]=='W') ? 1 : 0)
#define extract_GGA_NSEWind_m(foo)       ((GGA_EW_m(foo)) | ((GGA_NS_m(foo))<<4))


includes NMEA;

module NMEAM {

  provides interface NMEA;
}


implementation {

  command uint8_t NMEA.get_type   (const char * nmeastring) {
    return 0;
  }

  /** Uses hard-wired offsets because the LeadTek will return two sizes of
   * strings.  The first size is when there not enough satellites, so we can
   * return directly.  The second is when there are enough satellites, in
   * which case the fields are fixed.
   *
   * If this turns out to be "broken", it would not be much more
   * complicated to find the offset for each by counting commas,
   * because the number of fields is fixed.  In any case, this is
   * much faster than stuffing everything into an array as it is
   * done now in the MTS420 driver code.
   */
  command result_t NMEA.gga_parse (GGA_Data * ggad, const char * gga_string) {

    int i = 0;
    int numcommas = 0;
    int numsats = 0;
    const char * data;

    while (numcommas < 7) {   
      if (gga_string[i] == ',') {
	numcommas++;
      }
      i++;
    }
    data = &gga_string[i];
    numsats = extract_num_sats_m(data);
    if (numsats < 4) {
      return FAIL;
    }
    ggad->num_sats = numsats;

    data = &gga_string[7];
    ggad->hours = extract_hours_m(data);
    ggad->minutes = extract_minutes_m(data);
    ggad->dec_sec = extract_dec_sec_m(data);

    data = &gga_string[18];
    ggad->Lat_deg = extract_Lat_deg_m(data);
    ggad->Lat_dec_min = extract_Lat_dec_min_m(data);

    data = &gga_string[30];
    ggad->Long_deg = extract_Long_deg_m(data);
    ggad->Long_dec_min = extract_Long_dec_min_m(data);

    ggad->NSEWind = extract_GGA_NSEWind_m(gga_string);

    return SUCCESS;
  }


  command result_t NMEA.gll_parse (GLL_Data * gll_data, const char * gll_string) {

    const char * data; 
    enum {GLL_LAT_DEG = 7,
          GLL_NS_IND = 17,
          GLL_LONG_DEG = 19,
          GLL_EW_IND = 30,
          GLL_HOURS = 32,
	  GLL_STATUS = 43};

#define GLL_NS_m(foo)                    ((foo[GLL_NS_IND]=='N') ? 1 : 0)
#define GLL_EW_m(foo)                    ((foo[GLL_EW_IND]=='W') ? 1 : 0)
#define extract_GLL_NSEWind_m(foo)       ((GLL_EW_m(foo)) | ((GLL_NS_m(foo))<<4))

    data = &gll_string[GLL_LAT_DEG];
    gll_data->Lat_deg = extract_Lat_deg_m(data);
    gll_data->Lat_dec_min = extract_Lat_dec_min_m(data);

    data = &gll_string[GLL_LONG_DEG];
    gll_data->Long_deg = extract_Long_deg_m(data);
    gll_data->Long_dec_min = extract_Long_dec_min_m(data);

    data = &gll_string[GLL_HOURS];
    gll_data->hours = extract_hours_m(data);
    gll_data->minutes = extract_minutes_m(data);
    gll_data->dec_sec = extract_dec_sec_m(data);


    gll_data->status = gll_string[GLL_STATUS];

    gll_data->NSEWind = extract_GLL_NSEWind_m(gll_string);

    return SUCCESS;
  }

  command result_t NMEA.gsa_parse (GSA_Data * gsa_data, const char * gsa_string) {
    return FAIL;
  }

  command result_t NMEA.gsv_parse (GSV_Data * gsv_data, const char * gsv_string) {
    return FAIL;
  }

  command result_t NMEA.rmc_parse (RMC_Data * rmc_data, const char * rmc_string) {
    return FAIL;
  }

  command result_t NMEA.vtg_parse (VTG_Data * vtg_data, const char * vtg_string) {
    return FAIL;
  }

  command result_t NMEA.mss_parse (MSS_Data * mss_data, const char * mss_string) {
    return FAIL;
  }

}

