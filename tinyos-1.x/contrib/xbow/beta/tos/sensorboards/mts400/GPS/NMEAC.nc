

/**
 * Configuration for NMEA - 0183 parser.
 *
 * This code is part of the NSF-ITR funded 
 * FireBug project:
 * @url http://firebug.sourceforge.net
 *
 * @author David M. Doolin
 *
 * $Id: NMEAC.nc,v 1.1 2005/03/04 10:16:36 husq Exp $
 */

configuration NMEAC {

  provides interface NMEA;
}

implementation {

  components NMEAM;

  NMEA = NMEAM;

}
