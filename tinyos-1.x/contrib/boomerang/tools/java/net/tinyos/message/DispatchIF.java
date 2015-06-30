/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
package net.tinyos.message;

public interface  DispatchIF { 
    public void registerListener(Message m, MessageListener l);

    public void deregisterListener(Message m, MessageListener l);
}


