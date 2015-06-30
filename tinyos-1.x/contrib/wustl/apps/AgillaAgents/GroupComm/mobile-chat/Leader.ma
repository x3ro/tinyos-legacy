//-------------------------------------------------------------------------------------------------
// Group Communication Leader
//
// Heap Structure:
//   [0] = number of members
//   [1..n] = member locations
//
// Number of reactions: 2
//   (1) Distributes a group message.  
//       Tuple format: <"mbm", value>
//   (2) Adds a member to the group.
//       Tuple format: <"jng", location>
//-------------------------------------------------------------------------------------------------
                      pushc 0     // store the group member information on the heap
                      setvar 0    // heap[0] = initial number of members (0)        

// register a reaction sensitive to join messages
                      pusht location
                      pusht agentid
                      pushn jng
                      pushc 3
                      pushcl RXN_GROUP_JOIN
                      regrxn

// register a reaction sensitive to member broadcast messages   
                      pusht string
                      pusht string
                      pusht agentid
                      pushn mbm
                      pushc 4     // template = <"mbm", agentID, string, string>
                      pushc RXN_GROUP_SEND
                      regrxn      // register a reaction for member broadcast messages
    
// register a reaction sensitive to member update messages
    pusht value
    pusht agentid
    pushn upd
    pushc 3
    pushcl RXN_UPDATE_LOC
    regrxn

WAIT                  wait

// The group send reaction sensitive to <"mbm", string, string>
// Assumes heap[0] = number of agents and heap[1...n] are the agent's addresses
RXN_GROUP_SEND        pushc 25
                      putled
                      remove
                      pop
                      pop
                      pop
                      esetvar 19    // heap[19] = name
                      esetvar 18    // heap[18] = message
                      pushc 0
                      esetvar 17
RGS_LOOP              egetvar 17
                      inc
                      copy      // Stack:  cntr, cntr

                      esetvar 17    // heap[17] = cntr

                      getvar 0    // Stack:  # of members, cntr
                      cgt     // check whether the counter is > number of members
                      pushcl DONE
                      jumpc 

                      egetvar 18    // message        
                      egetvar 19    // member's name

                      egetvar 17    
                      pushc 2
                      mul         
                      dec     // 2*idx - 1
                      getvars     // each member's agent ID

                      //copy
                      //pushn rcv
                      //pushc 2
                      //pushloc uart_x uart_y
                      //rout  

                      pushn lbm
                      pushc 4     // tuple = <"lbm", member ID, name, message>

                      egetvar 17
                      pushc 2
                      mul     // 2*idx    
                      getvars     // get the member's address 
                      //pushloc uart_x uart_y
                      //copy
                      //pushn rcv
                      //pushc 2
                      //pushloc uart_x uart_y
                      //rout  

                      rout
                      pushc RGS_LOOP
                      jumps     // go back to STG_LOOP    
DONE                  endrxn      // end the reaction


                      
// The group join reaction sensitive to <"jng", location>
// Assumes heap[0] = number of agents and heap[1...n] are the agent's addresses
RXN_GROUP_JOIN        remove
                      //pushc 25
                      //putled   
                      pop     // pop number of fields
                      pop     // pop the string "jng"
                      getvar 0
                      inc
                      setvar 0    // heap[0]++
                      getvar 0
                      pushc 2
                      mul
                      dec
                      setvars     // heap[index*2-1] = agent id
                      getvar 0
                      pushc 2
                      mul
                      setvars     // heap[index*2] = member location
                      endrxn                  
    
RXN_UPDATE_LOC  pushc 4
    putled        // only set blue on if leader receives member update location
    remove
    pop     // pop number of fields
    pop     // pop the string "upd", Stack:  agentID, location
        
    findMatch
    inc     // the location is in the next index position Stack:  heap[idx] = location, new location

    copy
    getvars   // get the members old location
    pushn mlc
    pushc 2
    pushloc uart_x uart_y
    rout

    setvars     // save the new location
    clear
    pushc WAIT
    endrxn
    