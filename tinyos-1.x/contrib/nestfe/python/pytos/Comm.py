#$Id: Comm.py,v 1.1 2005/05/26 05:33:58 shawns Exp $

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
# @author Shawn Schaffert <sms@eecs.berkeley.edu>


import sys, os, string
from jpype import jimport, JObject, JProxy



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

    self._active[source] = openMoteIF( source )
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



class MessageCommError(Exception):
  pass



class MessageComm( object ) :

  def __init__( self ) :
    self._moteifCache = MoteIFCache()
    self._connected = []

  def connect( self , *moteComStr ) :
    for newMoteComStr in moteComStr :
      if newMoteComStr not in self._connected :
        self._moteifCache.get( newMoteComStr )
        self._connected.append( newMoteComStr )
      else :
        raise MessageCommError , "already connected to " + newMoteComStr

  def disconnect( self , *moteComStr ) :
    for oldMoteComStr in moteComStr :
      if oldMoteComStr in self._connected :
        self._connected.remove( oldMoteComStr )
      else :
        raise MessageCommError , "not connected to " + oldMoteComStr

  def send( self , addr , msg , *moteComStr ) :
    if len( moteComStr ) == 0 :
      moteComStr = self._connected
    for mc in moteComStr :
      # FIXME: send expects a Message, but only the TOSMsg subclass has set_addr
      self._moteifCache.get(mc).send( mote.TOS_BCAST_ADDR , msg.set_addr( addr ) )  

  def register( self , msg , callbackFcn , *moteComStr ) :
    msgListenerCallback = JProxy( jimport.net.tinyos.message.MessageListener , dict = { "messageReceived" : callbackFcn } )
    if len( moteComStr ) == 0 :
      moteComStr = self._connected
    for mc in moteComStr :
      self._moteifCache.get(mc).registerListener( msg , msgListenerCallback )

  def unregister( self , msg , callback , *moteComStr ) :
    if len( moteComStr ) == 0 :
      moteComStr = self._connected
    for mc in moteComStr :
      self._moteifCache.get(mc).deregisterListener( msg , callback )
