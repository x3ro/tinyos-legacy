// heap[0] = current member agent location
// heap[1] = previous member agent location

pushc 8
sleep

// register reaction:  Receive message from PDA, send message to member agent
// <'ocm', chat msg> (ocm - out chat msg)
    pusht string
    pushn ocm
    pushc 2
    pushcl SND_MSG
    regrxn

// register reaction:  Receive message from member agent, send message to PDA
// <"icm", chat msg> (icm - in chat msg)
    pusht string
    pushn icm
    pushc 2
    pushcl  RCV_MSG
    regrxn
    
// register reaction:  Receive MOVE message from PDA, tell member agent to follow
// <"pmv", new location> (pmv - PDA move)
    pusht location
    pushn pmv
    pushc 2
    pushcl MOVE
    regrxn


WAIT    wait

    

// reaction fired:  Receive message from PDA, send message to member agent
// From PDA:  <"ocm", chat msg>
// To Member:  <"ocm", chat msg> (ocm - out chat msg)
// # Future Optimization:  <'ocm', member agentID, chat msg> for multiple member agents on the same node
SND_MSG   remove    

    randnbr   // find the neighor node
    pushcl FND_MEM
    jumpc   // if success, forward msg to member agent  
    pop
    pop
    pop
    pushn ncn // if fail, send error message to PDA (ncn - no connection)
    pushc 1
    pushloc force_uart_x force_uart_y
    rout
    pushc 8   // blink 3 LED's twice
    putled
    pushc 31
    putled
    pushc 31
    putled
    pushc 31
    putled
    endrxn
  FND_MEM getvar 0  //   Stack:  (rnd neighbor loc, current member loc)
    ceq   // compare random neighbor location with the stored member location
    pushcl SAME_MEM_LOC
    jumpc     // if the neighbor loc is same as stored, proceed
    getvar 1  // if fails
    out
    // tell member agent to follow    
    getvar 0  
    setvar 1    // heap[1] = previous member agent location
    randnbr     
    pushc 0
    setvars     // heap[0] = current member agent location
    pushc 8     // Blink 3 LED's twice
    putled
    pushc 31
    putled
    pushc 31
    putled
    pushc 31
    putled
    endrxn            
    SAME_MEM_LOC  getvar 0    // heap[0] = curr member 
        rout      // send to current member 
        pushc 26
        putled      // toggle green LED when message sent to member
        endrxn

// reaction fired:  Receive message from member agent, send message to PDA
// From Member:  <"icm", chat msg> (icm - in chat msg)
RCV_MSG   remove      
    pushloc force_uart_x force_uart_y
    rout      // send tuple to base station   
    pushc 25    
    putled      // toggle red LED
    endrxn

// reaction fired:  Receive MOVE message from PDA, tell member agent to follow
// From PDA:  <"pmv", new location> (pmv - PDA move)
// To Member:  <"pmv", new location>
MOVE    remove      // remove the tuple
    pop     // pop off number of fields
    pop     // pop off "pmv", 
          //   Stack:  (new location)  
    getvar 0
    setvar 1    // heap[1] = previous member agent location
    pushc 0
    setvars     // heap[0] = current member agent location
    
    // tell member agent at the old location

    pushc 28
    putled      // toggle yellow LED
    endrxn