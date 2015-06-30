#
# Dummy script that runs the application, pausing and resuming once
# per second.
#

import time

def run():
    print "Running..."
    delay = 2
    while 1:
        time.sleep(delay)
        sim.pause()
        time.sleep(delay)
        sim.resume()
        
