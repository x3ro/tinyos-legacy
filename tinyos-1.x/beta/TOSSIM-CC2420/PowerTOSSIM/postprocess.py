#!/usr/bin/python
# postprocess.py
# Author: Victor Shnayder <shnayder at eecs.harvard.edu>
# Postprocessing script that reads PowerTOSSIM state transition log and
# computes power and energy numbers.

from sys import argv
import sys
import re
import shutil

usage = """USAGE: postprocess.py [--help] [--debug] [--nosummary]
[--detail[=basename]]  [--maxmotes N]
[--simple] [--sb={0|1}] --em file trace_file

--help:              print this help message
--debug:             turn on debugging output
--nosummary:         avoid printing the summary to stdout
--detail[=basename]: for each mote, print a list of 'time\\tcurrent' pairs
              to the file basename$moteid.dat (default basename='mote')
--em file:           use the energy model in file
--sb={0|1}:          Whether the motes have a sensor board or not. (default: 0)
--maxmotes:          The maximum of number of motes to support. 1000 by default.
--simple:            Use a simple output format, suitable for machine parsing

By default, uses energy model from energy_model.txt in the current directory,
prints summary.
"""

summary = 1
prettyprint = 1
detail = 0
lineno = 0   # The line number in the trace file
emfile = "energy_model.txt"
tracefile = ""
model = {}      # The energy model (mappings such as CPU_ACTIVE->8.0)
state = [{}]    # The current state of execution ([mote][component])
total = [{}]   # The energy totals

# Hmm... might not actually want 1000 open files.  I guess I could
# open and close each one after each write.  Or just keep all the
# logs in memory and then write them out one at a time.  For now, just
# open each file when necessary and leave it at that
data_file = []  
basename = 'mote'

voltage = None
prev_current = []
prev_time = []

prev_time_true = []

maxmotes = 1000
maxseen = 0
debug = 0
em = {}  # The energy model
sb = 0   # Whether there's a sensor board

#components = ["radio", "cpu", "cpu_cycles", "adc", "sensor", "led", "eeprom"]

# Types of total we want to track
totals = ["cpu", "radio", "adc", "leds", "sensor", "eeprom"]


def quit(showusage=0, error="Illegal arguments"):
    if error:
        print >> sys.stderr, "Error: ", error, "\n"

    if showusage:
        print >> sys.stderr, usage
    sys.exit()


# Handle arguments-this can be rewritten with a dictionary of lambdas, but
# that's for later (or I can just use an existing module)
def parse_args():
    global summary, maxmotes, emfile, tracefile, trace, argv, debug, basename
    global detail, prettyprint, sb
    argv = argv[1:]
    while argv:
        a=argv[0]
        if a == "--help":
            quit(1,"")
        elif a == "--nosummary":
            summary = 0
        elif a == "--simple":
            prettyprint = 0
        elif a.startswith("--detail"):
            detail = 1
            x=a.rfind('=')
            if x != -1:
                basename = a[x+1:]
                
        elif a.startswith("--sb="):
            t = a[5:]
            if t == "1":
                sb = 1
            elif t == "0":
                sb = 0
            else:
                quit(1)
            
                
        elif a == "--debug":
            debug = 1
        elif a == "--maxmotes":
            argv = argv[1:] # Consume this argument
            if not argv:
                quit(1)
            maxmotes = int(argv[0])
        elif a == "--em":
            argv=argv[1:]  # Consume this argument
            if not argv:
                quit(1)
            emfile = argv[0]  # Get the filename parameter
        else:
            tracefile = a
        argv = argv[1:]


    if tracefile == "":
        quit(1,"No tracefile specified")

    try:
        trace = open(tracefile)
    except IOError:
        quit(0,"Couldn't open trace file '"+tracefile+"'")


######### State initialization functions ##############

# Read energy model from file
def read_em():
    global model,lineno,em
    # Reads and parses the energy model file
    try:
        model = open(emfile)
    except IOError:
        quit(0,"Couldn't open energy model file '"+emfile+"'")

    l = model.readline()
    lineno += 1
    while l:
        l=l.strip()
        # Parse the line, skipping comments, blank lines
        if l == '' or l[0] == '#':
            l = model.readline()
            continue
#        print "splitting line '%s'" % l
        (k,v) = l.split()
        em[k]=float(v)
        l = model.readline()
        lineno += 1
    
def initstate():
    global state, total, voltage, prev_current, prev_time, data_file, pushed, prev_time_true
    read_em()
    # initialize the various lists...
    state = [None] * maxmotes
    total = [None] * maxmotes
    prev_current = [None] * maxmotes
    prev_time = [0] * maxmotes
    pushed = [0] * maxmotes
    prev_time_true = [0] * maxmotes
    data_file = [None] * maxmotes
    voltage = em['VOLTAGE']
    
    for mote in range(maxmotes):
        # Init each mote with base values
        state[mote] = {'radio':{'on':0, 'tx':0, 'rx':0, 'oscon':0,
                                'txpower':em['RADIO_DEFAULT_POWER']}, 
                       'cpu': 'IDLE',
                       'cpu_cycles':0,
                       'adc': 0,
                       'adc_on': 0,
          # For the moment, all the same, but can be changed later
                       'sensor_board': sb,  
                       'sensor': {},
                       'led': {},
                       'eeprom': {'read':0, 'write':0}}
        total[mote] = {}
        prev_current[mote]={}
        for k in totals:
            prev_current[mote][k] = 0
        prev_current[mote]['total']=0
        for t in totals:
            total[mote][t] = 0

######################## Current computation #######################

def get_cpu_current(mote):
    return em["CPU_"+state[mote]["cpu"]]

def get_sensor_current(mote):
    mystate = state[mote]['sensor']
    total = 0
    # If the sensor board is plugged it draws a constant base current 
    if state[mote]['sensor_board']:
        total += em.get('SENSOR_BOARD')
    for (type,value) in mystate.items():
        if value==1:
            total += em.get("SENSOR_"+type, 0)
    return total

def get_adc_current(mote):
    # FIXME: if we discover that sampling actually takes energy
    # in addition to the base cost, add it in if sampling.
    if state[mote]['adc_on']:
        return em['ADC']
    else:
        return 0

def tx_current(x):
    """ Return the radio current for transmit power x """
    return em["RADIO_TX_"+("%02X" % x)]

def get_radio_current(mote):
    # Note that this sets the total power of the radio, so we have to include
    # numbers like RADIO_ON.
    #the state is:  {'on':ON/OFF,'tx': TX/RX,'txpower':PowerLevel}
    mystate = state[mote]['radio']
    if debug:
        print 'get_radio_current():', mystate
    power = 0
    if mystate['on']:
        power += em['RADIO_ON']
        if mystate['oscon']:
            power += em['RADIO_OSCON']
            if mystate['tx']:
                power += tx_current(mystate['txpower'])
            elif mystate['rx']:
                power += em['RADIO_RX']
    return power;

def get_leds_current(mote):
    # Count how many leds are on:
    numon = state[mote]['led'].values().count(1)
    return numon * em['LED']

def get_eeprom_current(mote):
    # Assumes that EEPROM can't read and write at the same time
    # I believe that's correct
    if state[mote]['eeprom']['read']:
        return em['EEPROM_READ']
    if state[mote]['eeprom']['write']:
        return em['EEPROM_WRITE']
    return 0
    

# There should probably be one entry for each key of the totals
# defined above
current_fn_map = {
    'cpu': get_cpu_current,
    'radio': get_radio_current,
    'adc': get_adc_current,
    'leds':get_leds_current,
    'sensor':get_sensor_current,
    'eeprom':get_eeprom_current}


def get_current(mote):
    total = 0
    for k in current_fn_map.keys():
        total += current_fn_map[k](mote)
    return total

def print_currents():
    for m in range(maxseen+1):
        print "mote %d: current %f" % (m, get_current(m))


######################## Event processing ##########################

# Add together a mote time from the trace (in CPU cycles)
# and a energy model time (in ms)
def time_add(motetime, emtime):
    return motetime + emtime / 1000.0 * em.get("CPU_FREQ",7370000)

# The handlers should just update the state.  Other functions are
# responsible for keeping track of totals.

def cpu_cycle_handler(mote, time, newstate):
    # the cpu cycle messages always have a single number, which is
    # the total since beginning of execution
    global state
    state[mote]['cpu_cycles'] = float(newstate[1])

def cpu_state_handler(mote, time, newstate):
    # Here are the possible states, from PowerStateM.nc:
    #        char cpu_power_state[8][20] = {"IDLE", \
    #                                       "ADC_NOISE_REDUCTION", \
    #                                       "POWER_DOWN", \
    #                                       "POWER_SAVE", \
    #                                       "RESERVED", \
    #                                       "RESERVED", \
    #                                       "STANDBY", \
    #                                       "EXTENDED_STANDBY"}
    # The energy model should have keys for each of the form CPU_`state`
    global state
    state[mote]["cpu"] = newstate[1]

def adc_handler(mote, time, newstate):
    global state
    #FIXME: The ADC has to be on for any ADC event to work-check this
    action = newstate[1]
    if action == 'SAMPLE':
        state[mote]["adc"] = 1
    elif action == 'DATA_READY':
        state[mote]["adc"] = 0
    elif action == 'ON':
        state[mote]["adc_on"] = 1
    elif action == 'OFF':
        state[mote]["adc_on"] = 0
    else:
        quit(0,"Line %d: Syntax error: adc action %s unknown" % (lineno,action))

def radio_state_handler(mote, time, newstate):
    """
    The radio is one of the more complicated pieces:
    The possible values for newstate:
    ON  - turn radio on.  As far as I can tell, goes back
    to it's previous state
    OFF - turn radio off.
    TX - go into transmit mode.  The transmit power is the same
         as it was before (either the default, or the latest SetRFPower)
    RX - go into receive mode
    SetRFPower XX  for some hex value of XX-there should be an
    energy model entry for RADIO_TX_XX
    
    Thus, the state for the radio is:
    {'on':ON/OFF,'tx': TX/RX,'txpower':PowerLevel}
    """
    global state
    oldstate = state[mote]['radio']
    op = newstate[1]
    if op == "ON":
        # Parameters are set to defaults when turning on
        oldstate['on'] = 1
        oldstate['oscon'] = 0
        oldstate['tx'] = 0
        oldstate['rx'] = 0
        oldstate['txpower'] = em['RADIO_DEFAULT_POWER']
    elif op == "OFF": 
        oldstate['on'] = 0
        oldstate['oscon'] = 0
        oldstate['tx'] = 0
        oldstate['rx'] = 0
    elif op == "SetRFPower":
        oldstate['txpower'] = int(newstate[2],16)  # must be a hex number
    elif op == "TX":
        # The mica(1) stack, doesn't explicitly turn radio on, so
        # TX/RX transitions also turn it on.  Should be valid for mica2
        # as well, unless it tries to send while the radio is off, which
        # probably qualifies as a bug
        oldstate['on'] = 1 
        oldstate['oscon'] = 1
        oldstate['tx'] = 1
        oldstate['rx'] = 0
    elif op == "RX":
        oldstate['on'] = 1
        oldstate['oscon'] = 1
        oldstate['tx'] = 0
        oldstate['rx'] = 1
    elif op == "OSC_ON":
        oldstate['on'] = 1
        oldstate['oscon'] = 1
        oldstate['rx'] = 0
        oldstate['tx'] = 0
    else:
        quit(0,"Line %d: Syntax error: radio state %s unknown" % (lineno,op))
    

def led_state_handler(mote, time, newstate):
    """ The state for the LEDs is pretty simple:
        They start out off, and here we just keep track of which are on
        in a dictionary.  So the state[mote]['led'] looks like
        {'RED':onoff, 'GREEN':onoff, 'YELLOW':onoff}
    """
    global state
    msg = newstate[1]
    if msg.endswith("_OFF"):
        state[mote]['led'][msg[:-4]]=0
    else:
        assert msg.endswith("_ON")
        state[mote]['led'][msg[:-3]]=1

def sensor_state_handler(mote, time, newstate):
    global state
    # If we're doing sensor stuff, there must be a sensor board:
    type = newstate[1]
    action = newstate[2]
    if action == 'ON':
        state[mote]['sensor'][type] = 1
    elif action == 'OFF':
        state[mote]['sensor'][type] = 0
    else:
        quit(0, "Line %d: Syntax error: sensor state %s unknown"
             % (lineno, action))

def eeprom_state_handler(mote, time, newstate):
    global state
    type = newstate[1]
    action = newstate[2]
    if type == 'READ':
        if action == 'START':
            state[mote]['eeprom']['read'] = 1
        elif action == 'STOP':
            state[mote]['eeprom']['read'] = 0
        else:
            quit(0, "Line %d: Syntax error: EEPROM READ action %s unknown"
             % (lineno, action))
    elif type == 'WRITE':
        if action == 'START':
            state[mote]['eeprom']['write'] = 1
        elif action == 'STOP':
            state[mote]['eeprom']['write'] = 0
        else:
            quit(0, "Line %d: Syntax error: EEPROM WRITE action %s unknown"
             % (lineno, action))
    else:
        quit(0, "Line %d: Syntax error: EEPROM TYPE %s unknown"
             % (lineno, type))

# A table of event type to the appropriate handler
event_handler = {'CPU_CYCLES'  :    cpu_cycle_handler,
                 'CPU_STATE'   :    cpu_state_handler,
                 'ADC'  :          adc_handler,
                 'RADIO_STATE' :  radio_state_handler,
                 'LED_STATE'   :    led_state_handler,
                 'SENSOR_STATE': sensor_state_handler,
                 'EEPROM'      : eeprom_state_handler}


def time_diff(t_from, t_to):
    """Returns the difference, in seconds from 't_from' to 't_to', where both
    are expressed in cycles.  Uses the CPU_FREQ energy model parameter"""
    return (float(t_to) - float(t_from))/em['CPU_FREQ']

# "Totals" are the total amount of energy consumed since the very start.
# energy = time * (power = current * voltage)
# There are "totals" for each component (CPU, radio, ...).

# prev_current is the current from prev_time up till time (the current time).
# There is a prev_current['total']

# Updates every total for every timestep.  This is inefficient,
# because if the radio is on for 100 events, there's no need to do 100
# small adds But it's simpler this way.  Can fix it (by making
# prev_time parametrized by total type) if it's a problem
def update_totals(time):
    global total
    for m in range(maxseen+1):
        for t in totals: # for each str in ["cpu", "radio", ...]
            td = time_diff(prev_time[m], time)
            if td > 0:
                total[m][t] += td * prev_current[m][t] * voltage

def update_currents(time):
    global prev_time, prev_current, pushed, prev_time_true
    for m in range(maxseen+1):
#        pt = int(prev_time[m])
#        pt = int(prev_time_true[m])
#        t = int(time)
#        if pt >= t:
#            print 'pushing t =', t, 'to pt + 1 =', pt + 1
#            t = pt + 1000000
#            pushed[m] += 1000000 # + (pt - t)
#        else:
#            print 't = ', t, ', pt =', pt
#            pushed[m] = 0
#        time = t
        prev_time[m] = int(time)
#        prev_time_true[m] = t + 1000000
        for total in totals:
            prev_current[m][total] = current_fn_map[total](m)


def dump_currents(mote,time):
    global data_file, debug, prev_time_true
    m=mote
    if not data_file[m]:
        # Open the file
        data_file[m] = open(basename + str(m)+".dat", "w")
        # Write the header
        data_file[m].write("#%11s" % "time");
        for x in ['total'] + totals:
            data_file[m].write("%12s" % x)
        data_file[m].write("\n")


    if debug: print prev_current[m]['total'], get_current(m)
    if prev_current[m]['total'] != get_current(m):
        # To make a square wave, print the previous currents up to "just
        # before now", then print the new currents
        tm = float(time) / em['CPU_FREQ']
        ptm = prev_time_true[m]
        #print "tm %f ptm %f" % (tm, ptm)
        if ptm >= tm:
            tm = ptm + 0.000001
            #print "BUMPED tm %f ptm %f" % (tm, ptm)

        data_file[m].write("%15.9f" % tm)
        for t in ['total'] + totals:
            c = float(prev_current[m][t])
            data_file[m].write("%15.9f" % c)
        data_file[m].write("\n");

        tm = tm + 0.000000001
        ptm = tm + 0.000000001
        c = get_current(m)
        # Note: we are updating the 'total' field!
        prev_current[m]['total'] = c
        data_file[m].write("%15.9f%15.9f" % (tm,c))
        for t in totals:
            c = current_fn_map[t](m)
            data_file[m].write("%15.9f" % c);
        data_file[m].write("\n");

        data_file[m].flush()

        prev_time_true[m] = ptm

dbg_unknown_event_types = {}

# Takes a line, parses it, and performs the appropriate changes to the
# mote state and totals.
# The line format we expect consists of whitespace separated fields:
# DATA can consist of more than 1 field, but the rest must not
# junk POWER: Mote # STATE_TYPE {DATA...} at TIME(in cycles)
def handle_event(l):
    global maxseen, detail


    if debug: print lineno, l
    event = l.split()
    # Check if this is a power event
    if event[1] != "POWER:":
        return
    
    mote = int(event[3])
    if(mote > maxseen): maxseen = mote
    time = event[-1]
    #    print "handling event: '%s'" % l
    #    print event
    if event[4] in event_handler:
        # Update the totals up to just before this event
        update_totals(time)
        # Update the state due to this event
        event_handler[event[4]](mote,time,event[4:-2])
        if detail:
            # At this point, the state is updated, but still have the old
            # current values
            dump_currents(mote,time)
        # Update the prev_current values
        update_currents(time)
        
    else:
        global dbg_unknown_event_types
        if not event[4] in dbg_unknown_event_types:
            print "Don't know how to handle "+event[4]+" events"
            dbg_unknown_event_types[event[4]] = 1


# Post-process the detailed output file.
# Basically, clean up the dual-timestamped events.
# Currently, we only keep the last one; this may or may not be correct!
def cleanup_details():
    global data_file, maxseen
    for mote_id in range(0, maxseen + 1):
        waiting_line = None
        prev_time = -1
        time = -2

        data_file_name = basename + str(mote_id) + '.dat'
        data_file[mote_id].close()
        data_file[mote_id] = open(data_file_name, "r")

        tmp_file_name = basename + str(mote_id) + '.tmp'
        tmp_file = open(tmp_file_name, 'w')

        lines = data_file[mote_id].readlines()
        line_numbers = range(len(lines))
        for line, line_number in zip(lines, line_numbers):
            # special lines
            if line.startswith('#'):
                tmp_file.write(line)
                tmp_file.write('0 0 0 0 0 0 0 0\n')
                continue

            line = ' ' + line # pad it with a space
            fields = re.split('\s+', line)
            time = float(fields[1])
            line = line[1:] # remove the space we added
            if time == prev_time:
                waiting_line = line
            elif time > prev_time:
                if waiting_line != None:
                    tmp_file.write(waiting_line)
                waiting_line = line
                prev_time = time
            # We should never be going back in time.
            # This assumes we removed the step-function code in dump_currents().
            else:
                assert time <= prev_time
                quit(error = "we went back/stood still in time! line %d: %f < %f" % (line_number, time, prev_time))

        assert waiting_line != None
#        if waiting_line != None:
#            tmp_file.write(waiting_line)

        tmp_file.close()
        #shutil.move(tmp_file_name, data_file_name)

########################  "Main" code ###################

def print_summary():
    global total
    global maxseen
    print "maxseen %d" % maxseen
    for mote in range(maxseen+1):
        sum = 0
        if not prettyprint:
            s = str(mote)+"   "
        for t in totals:
            if prettyprint:
                print "Mote %d, %s total: %f" % (mote, t, total[mote][t])
            else:
                s += "%.4f" % total[mote][t]
                s += "   "
            sum += total[mote][t]
        cpu_active_e = state[mote]['cpu_cycles'] * voltage * em['CPU_ACTIVE']/em['CPU_FREQ']
        if prettyprint: 
            print "Mote %d, cpu_cycle total: %f" % (mote, cpu_active_e)
        else:
            s += "%.4f" % cpu_active_e
            s += "   "
        sum += cpu_active_e
        if prettyprint:
            print "Mote %d, Total energy: %f\n" %(mote, sum)
        else:
            s += "%.4f" % sum
            print s


if __name__=='__main__':
    parse_args()
    initstate()
    lineno = 1
    l=trace.readline()
    while l:
        handle_event(l)
        lineno += 1
        l = trace.readline()
#        print "> ",
#        sys.stdin.readline()

    cleanup_details()

    if summary:
        print_summary()


    


