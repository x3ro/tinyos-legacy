import pytos
from jpype import *

nucleusInterface = jimport.net.tinyos.nucleus.NucleusInterface()

def queryDeluge(image_num,delay):
  ni = nucleusInterface
  ni.loadSchema('nucleusSchema.xml')
  return ni.get( ni.QUERY_ATTR, ni.DEST_LINK, ni.RESPONSE_LOCAL, delay,
    ["DelugeCompletedPages", "DelugeTotalPages"], [image_num,image_num] )

def printResults(rv):
  for i in range(0,rv.size()):
    for k in rv[i].attrs.keySet().toArray():
      print "%2d: %s = %s" % (rv[i].from_, k, rv[i].attrs[k].value.toString())

def plotDeluge(rv):
  ids = [(rv[i].from_,i) for i in range(0,rv.size())]
  ids.sort()
  for i in range(0,len(ids)):
    v = rv[ids[i][1]]
    complete = v.attrs["DelugeCompletedPages"].value.intValue()
    total = v.attrs["DelugeTotalPages"].value.intValue()
    s = subplot(2, 2, i+1)
    pie([ complete, total-complete ], colors=["#ffa000","#000000"])
    title("Node %d: %3.0f%% complete" % (v.from_, 100*complete/total))

