// heap[0] = current member agent location
// heap[1] = previous member agent location

pushc 25
putled
pushc 8
sleep
pushc 25
putled    //blink red LED for 1s

randnbr
copy
setvar  0  // current member
setvar  1 

// register reaction:  Receive message from PDA, send message to member agent
// <'ocm', screen name, chat msg> (ocm - out chat msg)
    pusht string
    pusht string
    pushn ocm
    pushc 3
    pushcl SND_MSG
    regrxn

// register reaction:  Receive message from member agent, send message to PDA
// <"icm", screen name, chat msg> (icm - in chat msg)
    pusht string
    pusht string
    pushn icm
    pushc 3
    pushcl  RCV_MSG
    regrxn
   
WAIT          wait


// reaction fired:  Receive message from PDA, send message to member agent
// From PDA:  <"ocm", screen name, chat msg>
// To Member:  <"ocm", screen name, chat msg> (ocm - out chat msg)
// # Future Optimization:  <'ocm', member agentID, chat msg> for multiple member agents on the same node
SND_MSG         remove                 
                randnbr
                rjumpc GOT_NBR  //   Stack:  neighbour loc
                pushc 8
                putled      
                pushc 31
                putled    // light all 3 LED if no neighbor found
                clear
                pushn nma // tell PDA that it is not in range of network
                pushc 1
                pushloc force_uart_x force_uart_y
                rout
                rjump WAIT 
GOT_NBR   getvar  0 //   Stack:  (member loc, neighbor loc, <3, "ocm", screen name, chat msg>)
    ceq
    rjumpc  GOT_MEM   //   Stack:  (<3, "ocm", screen name, chat msg>)
    randnbr
    rout      // place outgoing tuple in member's new location.  it will find it when it arrives...
    randnbr   
    pushn mov
    pushc 2   
    getvar  0
    rout        // fetch the member:  <"mov", new location>
    getvar  0   // heap[1] = old loc
    setvar  1
    randnbr     // heap[0] = curr loc
    setvar  0
    endrxn
  GOT_MEM getvar  0 // member agent is on neighbor node, 
          rout          // send tuple to member agent
          pushc 26        // toggle green
          putled              
          endrxn


// reaction fired:  Receive message from member agent, send message to PDA
// From Member:  <"icm", chat msg> (icm - in chat msg)
RCV_MSG   remove      
    pushloc force_uart_x force_uart_y
    rout      // send tuple to base station   
    pushc 25    
    putled      // toggle red LED
    endrxn
