MobiLoc - Mobility Enhanced Localization
Prabal Dutta and Sarah Bergbreiter
CS294-1 Class Project

We propose to study the symbiotic relationship between mobility, 
navigation, and localization in the context of wireless sensor networks
and mobile objects.  We observe that mobility can aid in network localization
and that once localized, the network nodes can localize and track a mobile
object (robot) and guide its navigation.  Our motivation, and the 
ultimate goal of this work, is to realize the following scenario:

A set of sensor network nodes are dropped onto a field at uknown locations
and orientations.  An unfriendly mobile object travels through the sensor
netowrk in a structured (or random) walk.  The network nodes determine their
own locations by estimating the range to this mobile object in a coordinated
fashion and applying a transform to these range estimates to yield the
node positions in some global coordinate frame.  Once localized, the nodes
may multilaterate the location of the mobile object and guide its motion
to locations and events of interest within the sensor network.
