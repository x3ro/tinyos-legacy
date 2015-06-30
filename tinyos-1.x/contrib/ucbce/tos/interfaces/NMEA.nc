

/**
 * Interface for defining behavior of NMEA - 0183 parser.
 *
 * This code is part of the NSF-ITR funded 
 * FireBug project:
 * @url http://firebug.sourceforge.net
 *
 * @author David M. Doolin
 *
 * $Id: NMEA.nc,v 1.1 2004/08/31 22:15:19 doolin Exp $
 *
 */

includes NMEA;

interface NMEA {

  command uint8_t  get_type   (const char * nmeastring);
  command result_t gga_parse (GGA_Data * gga_data, const char * gga_string);
  command result_t gll_parse (GLL_Data * gll_data, const char * gll_string);
  command result_t gsa_parse (GSA_Data * gsa_data, const char * gsa_string);
  command result_t gsv_parse (GSV_Data * gsv_data, const char * gsv_string);
  command result_t rmc_parse (RMC_Data * rmc_data, const char * rmc_string);
  command result_t vtg_parse (VTG_Data * vtg_data, const char * vtg_string);
  command result_t mss_parse (MSS_Data * mss_data, const char * mss_string);

}
