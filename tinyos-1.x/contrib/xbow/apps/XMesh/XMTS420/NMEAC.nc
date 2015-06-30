

/**
 * Configuration for NMEA - 0183 parser.
 *
 * This code is part of the NSF-ITR funded 
 * FireBug project:
 * @url http://firebug.sourceforge.net
 *
 * @author David M. Doolin
 *
 * $Id: NMEAC.nc,v 1.1 2004/12/10 05:46:12 husq Exp $
 */

configuration NMEAC {

  provides interface NMEA;
}

implementation {

  components NMEAM;

  NMEA = NMEAM;

}
