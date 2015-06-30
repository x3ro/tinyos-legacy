/*
 * EdgeInfo.java
 *
 * Created on January 21, 2002, 1:37 PM
 */

package net.tinyos.moteview.util;

/**
 *
 * @author  Joe Polastre &lt;<a href="mailto:polastre@cs.berkeley.edu">polastre@cs.berkeley.edu</a>&gt;
 */
public class EdgeInfo {

    /** Creates new EdgeInfo */
		protected Integer sourceNodeNumber;
		protected Integer destinationNodeNumber;

		public EdgeInfo(Integer pSourceNodeNumber, Integer pDestinationNodeNumber)
		{
			sourceNodeNumber = pSourceNodeNumber;
			destinationNodeNumber = pDestinationNodeNumber;
		}


		public Integer GetSourceNodeNumber(){return sourceNodeNumber;}
		public Integer GetDestinationNodeNumber(){return destinationNodeNumber;}

}
