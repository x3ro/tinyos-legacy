* Please compile with cc2420x library coming with TinyOS, as "make micaz cc2420x"
  
* Program one node as a Base station.

* Program one node with ID 0 as a Reference Broadcaster Node with the "Reference" application. This node will send QUERY packets periodically.

* Program 10 nodes with "FloodPISyncApp" or "AvgPISyncApp" by selecting through the makefile so that they run PISync. When these nodes receive QUERY packets from the Reference Broadcaster node, they will broadcast their logical clock at the receipt time in order according to their IDs. Base station will catch these packets and you can observe their synchronization error. 