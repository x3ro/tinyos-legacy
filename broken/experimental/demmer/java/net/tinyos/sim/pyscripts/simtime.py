#
# simtime is a simple module that implements time conversion from real
# time to simulator time which is in 4MHz tick units.
#

onesec = long(4000000)
onemin = long(onesec * 60)
onehr  = long(onemin * 60)

def secs(n):
    return n * onesec

def mins(n):
    return n * onemin

def hrs(n):
    return n * onehr


