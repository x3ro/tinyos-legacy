#$Id: MoteIF.py,v 1.1 2005/05/03 07:38:38 cssharp Exp $

# "Copyright (c) 2000-2003 The Regents of the University of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement
# is hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
# OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."

# @author Cory Sharp <cssharp@eecs.berkeley.edu>

import sys, os, string
from jpype import jimport, JObject

def openMoteIF(sourceName) :

  tinyos = jimport.net.tinyos

  messenger = JObject( None, tinyos.util.Messenger )
  source = tinyos.packet.BuildSource.makePhoenix( sourceName, messenger )
  source.setPacketErrorHandler( jimport.PyPhoenixError(source) )

  moteif = tinyos.message.MoteIF( source )

  if source.isAlive() :
    moteif.start()
  else :
    raise RuntimeError, "could not open MoteIF %s" % sourceName

  return moteif

class MoteIFCache(object) :

  def __init__(self) :
    self._active = {}

  def get(self,source) :
    if self.isAlive(source) :
      return self._active[source]

    sys.stderr.write( "get MoteIF for %s\n" % source )
    self._active[source] = openMoteIF( "serial@%s:telos" % source )
    return self._active[source]

  def isAlive(self,source) :
    if self.has(source) :
      if self._active[source].getSource().isAlive() :
	return True
    return False

  def has(self,source) :
    if self._active.has_key(source) :
      return True
    return False

