/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
package com.moteiv.trawler;

import com.moteiv.oscope.Channel;

public interface ChannelDataSource { 
    public void setSensorChannel(Channel newSensorChannel);
    public Channel getSensorChannel();
}