// $Id: testGpsJava.java,v 1.1 2005/04/25 22:38:25 shawns Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @author Shawn Schaffert
 */

import java.text.SimpleDateFormat;
import java.util.Date;
import java.text.DecimalFormat;

class testGpsJava {

    static {
        System.loadLibrary("GpsBoxJava");
    }

    public static void main( String[] args ) {

	// log filename
	//SimpleDateFormat sdf = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss");
	//Date d = new Date();
	//String filename = sdf.format( d );
	//filename += ".gpsLog";
	//System.out.println( "Logging data to " + filename );
	//System.out.println( "Press q to quit" );

	GpsBox gps = new GpsBox( "serial,/dev/ttyS0,115200" );

	DecimalFormat df = new DecimalFormat();
	df.setMaximumFractionDigits(2);
	df.setMinimumFractionDigits(2);

	while (true) {

	    if ( gps.iterate(0.3) ) {
		
		GpsPrtkb prtkb = gps.prtkb();
		GpsVlhb vlhb = gps.vlhb();
		double x = gps.rfs().getCurrentX();
		double y = gps.rfs().getCurrentY();
		
		String str = "";
		str += "sats:" + prtkb.getSats();
		str += " lat:" + df.format(prtkb.getLatitude());
		str += " long:" + df.format(prtkb.getLongitude());
		str += " h:" + df.format(prtkb.getHeight());
		str += " lat-d:" + df.format(prtkb.getDev_latitude());
		str += " long-d:" + df.format(prtkb.getDev_longitude());
		str += " h-d:" + df.format(prtkb.getDev_height());
		str += " status-s:" + prtkb.getStatus_solution();
		str += " status-r:" + prtkb.getStatus_RTK();
		str += " type:" + prtkb.getPos_type();
		str += " x:" + df.format(x);
		str += " y:" + df.format(y);
		
		System.out.println(str);


// 		String str = "";
// 		str += prtkb.getWeek();
// 		str += " " + prtkb.getTime();
// 		str += " " + prtkb.getLag();
// 		str += " " + prtkb.getSats();
// 		str += " " + prtkb.getSats_RTK();
// 		str += " " + prtkb.getSats_RTK_L1_L2();
// 		str += " " + prtkb.getLatitude();
// 		str += " " + prtkb.getLongitude();
// 		str += " " + prtkb.getHeight();
// 		str += " " + prtkb.getUndulation();
// 		str += " " + prtkb.getId();
// 		str += " " + prtkb.getDev_latitude();
// 		str += " " + prtkb.getDev_longitude();
// 		str += " " + prtkb.getDev_height();
// 		str += " " + prtkb.getStatus_solution();
// 		str += " " + prtkb.getStatus_RTK();
// 		str += " " + prtkb.getPos_type();
// 		str += " " + prtkb.getIdle();
// 		str += " " + prtkb.getStation();
// 		str += " " + vlhb.getWeek();
// 		str += " " + vlhb.getSeconds();
// 		str += " " + vlhb.getLatency();
// 		str += " " + vlhb.getAge();
// 		str += " " + vlhb.getHspeed();
// 		str += " " + vlhb.getTog();
// 		str += " " + vlhb.getVspeed();
// 		str += " " + vlhb.getStatus_solution();
// 		str += " " + vlhb.getStatus_velocity();
// 		str += " " + x;
// 		str += " " + y;

	    }

	}
    }
}
