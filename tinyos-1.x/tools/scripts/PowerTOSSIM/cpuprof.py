#!/usr/bin/python

# Script to do convert the bb exec counts into some useful form.
# reads the files bb_cycle_map, bb_exec_cnt, bb_linenum_map in the
# current directory

import sys;

COUNT_BLOCKS = 0
if '--countbbs' in sys.argv:
    COUNT_BLOCKS = 1

NUM_BLOCKS = 20   # Number of most expensive basic blocks to print
NUM_FILES = 20   # Number of most expensive files to print

nummotes = 0
cycle_map = {}
for line in  open('bb_cycle_map').readlines():
    (bb, cnt) = line.split('\t')
    cycle_map[int(bb)] = float(cnt)


filecycles = {}  # File->cycles mapping

exec_cnt = {}
# Skip the first line-it's a total that we don't need
for line in open('bb_exec_cnt').readlines():
    if not line.startswith('mote'):   # stupid me put totals in the file format
        (mote, bb, cnt) = line.split()
        mote = int(mote)
        if mote > nummotes:
            nummotes = mote
        if not mote in exec_cnt:
            exec_cnt[mote] = {}
        exec_cnt[mote][int(bb)] = float(cnt)

nummotes += 1

linenum_map = {}
for line in  open('bb_linenum_map').readlines():
    (bb, l) = line.split('\t')
    linenum_map[int(bb)] = l

def mycmp(a, b):
    # Want to sort in reverse order, so exchange a, b
    if COUNT_BLOCKS:
        return cmp(exec_cnt[m][b], exec_cnt[m][a])
    else:
        return cmp(exec_cnt[m][b] * cycle_map.get(b,0),
                   exec_cnt[m][a] * cycle_map.get(a,0))

# Takes a dictionary.  Returns the set of keys sorted by value
def sortdict(d):
    keys = d.keys()
    keys.sort(lambda a,b:cmp(d[a],d[b]))
    return keys

if COUNT_BLOCKS:
    print "Block counts:"
else:
    print "Cycle counts:"
print "     %12s%12s%12s%12s%12s%12s%12s" % ('App', 'System',
                                             'Lib', 'Interfaces',
                                             'Platform',  'Misc',  'Total')
for m in range(nummotes):
    filecycles = {}
    platform = 0
    app = 0
    system = 0
    interfaces = 0
    lib = 0
    misc = 0
    for bb in exec_cnt[m]:
        if COUNT_BLOCKS:
            cycles =  exec_cnt[m][bb]
        else:  # Count cycles instead
            cycles = cycle_map.get(bb,0) * exec_cnt[m][bb]

        # Get the filename
        t = linenum_map[bb].rfind(':')
        filename = linenum_map[bb][:t]
        if not filename in filecycles:
            filecycles[filename] = cycles
        else:
            filecycles[filename] += cycles
        
        if linenum_map[bb].find('/platform/') != -1:
#            print 'platform: ', linenum_map[bb]
            platform += cycles
        elif linenum_map[bb].find('/tos/system') != -1:
#           print 'system: ', linenum_map[bb]
            system += cycles
        elif linenum_map[bb].find('/tos/lib') != -1:
            lib += cycles
        elif linenum_map[bb].find('/tos/interfaces') != -1:
            interfaces += cycles
        elif linenum_map[bb].find('/apps/') != -1:
#            print 'app: ', linenum_map[bb]
            app += cycles
        else:
#            print 'misc: ', linenum_map[bb]
            misc += cycles

    print "%3d: %12s%12s%12s%12s%12s%12s%12s" % (m,app, system, lib,
                                                 interfaces, platform,
                                                 misc,
                                                 app+system+platform+misc)

    # Now lets figure out the top K basic blocks for this mote:
    blocks = exec_cnt[m].keys()
    blocks.sort(mycmp)
    print "Mote %d: %d most expensive BBs:"  % (m, NUM_BLOCKS)
    for bb in blocks[:NUM_BLOCKS]:
        print "%6d%15.1f   %s" % (bb, exec_cnt[m][bb], linenum_map[bb])
    
    # And now the files
    files = sortdict(filecycles)
    files.reverse()
    print "Mote %d: %d most expensive files:"  % (m, NUM_FILES)
    for f in files[:NUM_BLOCKS]:
        print "%15.1f   %s" % (filecycles[f], f)
