#
# Dummy script that registers itself to get events and prints them out
#

from net.tinyos.sim.event import *

eventcount = 0;

def handle_event(event):
    # XXX/demmer i don't know why this is necessary while the other
    # vars can be referred to without needing to explicitly declare
    # them as global. the best thing i can come up with is that the
    # PythonInterpreter has all the reflected java objects in scope
    # all the time, while the pure python variables need to be
    # explicitly scoped
    global eventcount

    if (DebugMsgEvent.isInstance(event)):
        print "Got DebugMsgEvent event"

    print "Got event", eventcount, ":", event
    eventcount = eventcount + 1
    if (eventcount == 10):
        print "10th event, unregistering id", event_id
        interp.removeEventHandler(event_id)
        interp.removeEventHandler(event_id2)
        sim.pause()

def handle_event2(event):
    print "handle_event2"

def handle_init(event):
    global event_id
    global event_id2
    
    print "Got init event. numMotes:", event.getNumMotes();
    interp.removeEventHandler(init_id)
    event_id = interp.addEventHandler(handle_event);
    event_id2 = interp.addEventHandler(handle_event2);


print "printevent registering init event handlers"
init_id = interp.addEventHandler(handle_init, TossimInitEvent);
