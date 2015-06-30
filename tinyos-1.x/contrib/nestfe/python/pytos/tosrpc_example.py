import sys, string, re
from jpype import jimport

BaseTOSMsg = jimport.net.tinyos.message.BaseTOSMsg

def sorted_keys( dict ) :
  keys=dict.keys(); keys.sort(); return keys

def _msgpack( msg, type, value ) :
  print "  packing %s = %s" % (type, value)
  nbits = { 'uint8_t':8, 'uint16_t':16, 'uint32_t':32 }[type];
  n = msg.get_length()
  msg.setUIntElement( BaseTOSMsg.offsetBits_data(0) + 8*n, nbits, value )
  msg.set_length( n + nbits/8 )

class rpcfunc(object) :
  
  def __init__(self, par) :
    self._par = par

  def __call__(self, *args) :

    if len(self.argin) != len(args) :
      raise TypeError, "%s takes exactly %d arguments (%d given)" % (
	self.get_signature(), len(self.argin), len(args) )

    msg = BaseTOSMsg()
    for i,arg in enumerate(args) :
      _msgpack( msg, self.argin[i][0], arg )
    print
    jimport.java.lang.System.out.println(msg)

    return msg

  def __getattribute__(self, name) :
    try :
      return object.__getattribute__(self,name)
    except :
      if self._par.has_key(name) :
	return self._par.get( name )
      raise

  def get_signature(self) :
    return "%s %s( %s )" % ( self.argout[0][0], self.name,
      string.join([string.join(x) for x in self.argin],', ') )

class PtRpc(object) :

  def __init__(self, rpcfile) :

    self._funcs = {}
    par = None

    f = open(rpcfile,'r')
    lines = f.readlines()
    f.close()
    lines.append('')
    for line in lines :
      words = string.split(line)
      if len(words) == 0 :
	if par is not None :
	  self._funcs[par['name']] = rpcfunc(par)
	  par = None
	pass
      elif words[0] == 'name' :
        par = { 'name':words[1], 'argin':[], 'argout':[] }
      elif words[0] == 'id' :
        par['rpcid'] = words[1]
      elif words[0] == 'in' :
	par['argin'].append( [words[1], words[2]] )
      elif words[0] == 'out' :
	par['argout'].append( [words[1], words[2]] )

  def __getattribute__(self, name) :
    try :
      return object.__getattribute__(self,name)
    except :
      if self._funcs.has_key(name) :
	return self._funcs.get(name)
      raise

  def list(self) :
    for name in sorted_keys(self._funcs) :
      print self._funcs.get(name).get_signature()

