/*
 * CVS Information
 * 
 * File:     $RCSfile: Xwiring.java,v $
 * Revision: $Revision: 1.1 $
 * Author:   $Author: lachenmann $
 * Date:     $Date: 2007/02/20 12:33:05 $
 */
// $Id: Xwiring.java,v 1.1 2007/02/20 12:33:05 lachenmann Exp $
/*									tab:4
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

package net.tinyos.nesc.dump.xml;

import java.util.Collection;
import java.util.HashSet;

import org.xml.sax.*;

/**
 * Top-level wiring graph.
 */
public class Xwiring extends NDElement
{
    /**
     * The application's wiring graph
     */
    public static WiringGraph wg = new WiringGraph();
    
    public Collection wires = new HashSet();

    public void child(NDElement subElement) {
	wg.addEdge((Xwire)subElement);
	wires.add(subElement);
    }
}
