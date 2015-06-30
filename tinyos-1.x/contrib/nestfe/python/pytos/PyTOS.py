#$Id: PyTOS.py,v 1.2 2005/05/21 20:13:58 shawns Exp $

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
# @auther Shawn Schaffert

import string, threading, MoteIF, Deluge
from jpype import jimport

_moteifCache = MoteIF.MoteIFCache()

class Timer( object ) :

  def __init__( self , callback=None , period=0 , numFiring=0 , waitTime=0 ) :
    self.period = period   #must be >= 0
    self.waitTime = waitTime  #must be >=0
    self.numFiring = numFiring  # 0 = forever, 1 = one-shot , 2+ = finite repeats
    self.callback = callback

  def __fireNext( self ) :
    if self.numFiring == 0 :
      self.timer = threading.Timer( self.period , self.__callback ).start()
    elif self.remainingFirings == 0 :
      self.timer = None
    else :
      self.timer = threading.Timer( self.period , self.__callback ).start()
      self.remainingFirings -= 1

  def __callback( self ) :
    if self.stopTimer :
      self.timer = None
    else :
      self.__fireNext()
      if self.callback:
        self.callback()

  def __waitOver( self ) :
    self.__fireNext()

  def start( self ) :
    self.timer = None
    self.remainingFirings = self.numFiring
    self.stopTimer = False
    if self.waitTime > 0 :
      self.timer = threading.Timer( self.waitTime , self.__waitOver ).start()
    else :
      self.__fireNext()

  def cancel( self ) :
    self.stopTimer = True


class MessageComm(Exception):
  pass

class MessageComm( object ) :

  def __init__( self ) :
    self._moteifCache = _moteifCache
    self._connected = []

  def connect( self , *moteComStr ) :
    for newMoteComStr in moteComStr :
      if newMoteComStr not in self._connected :
        self._moteifCache.get( newMoteComStr )
        self._connected.append( newMoteComStr )
      else :
        raise MessageCommError , "Already connected to " + newMoteComStr

  def disconnect( self , *moteComStr ) :
    for oldMoteComStr in moteComStr :
      if oldMoteComStr in self._connected :
        self._connected.remove( oldMoteComStr )
      else :
        raise MessageCommError , "Not connected to " + oldMoteComStr

  def send( addr , msg , *moteComStr ) :
    if length( moteComStr ) == 0 :
      moteComStr = self._connected
    for mc in moteComStr :
      mote = self._moteifCache.get( mc )
      mote.send( mote.TOS_BCAST_ADDR , msg.set_addr( addr ) )  # FIXME: send expects a Message, but only the
                                                               # TOSMsg subclass has set_addr

  def register( msg , callback , *moteComStr ) :
    if length( moteComStr ) == 0 :
      moteComStr = self._connected
    for mc in moteComStr :
      mote.registerListener( msg , callback )

  def unregister( msg , callback , *moteComStr ) :
    if length( moteComStr ) == 0 :
      moteComStr = self._connected
    for mc in moteComStr :
      mote.deregisterListener( msg , callback )


class Comm(object) :

  def __init__(self, source) :
    self._source = string.upper(source)
    self.deluge = Deluge.Deluge(self)

  def __getattribute__(self, name) :
    try :
      return object.__getattribute__(self,name)
    except :
      pass

    if name == "moteif" :
      return _moteifCache.get( self._source )

    raise AttributeError, "%s has no attribute %s" % (self, name)

  def close(self) :
    if _moteifCache.isAlive(self._source) :
      _moteifCache.get(self._source).shutdown()
      return True
    return False

class CommCache(object) :

  def __init__(self) :
    self._active = {}

  def get(self,source) :
    if not self.has(source) :
      self._active[source] = Comm(source)
    return self._active[source]

  def has(self,source) :
    return self._active.has_key(source)

class PyTOS(object) :

  def __init__(self) :
    self._commCache = CommCache()

  def __getattribute__(self, name) :
    try :
      return object.__getattribute__(self,name)
    except :
      return self._commCache.get( name )

