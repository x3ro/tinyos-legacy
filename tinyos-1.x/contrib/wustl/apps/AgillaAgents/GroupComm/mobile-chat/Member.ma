// screen name
// groupname:  hard coded as "abc"
// heap[0] = PDA+Proxy location
// heap[1] = leader location

BEGIN               randnbr     // look for a node in the network
                    rjumpc NEIGHBOR_FOUND  
                    rjump BEGIN
NEIGHBOR_FOUND      smove   // migrate to the node  

                    pushc 31
                    putled    // toggle all LED

// Query Base station, Discover the leader location
                    loc
                    pushn abc // group name = "abc", HARD CODED
                    pushn req
                    pushc 3   
                    pushloc uart_x uart_y
                    rout    // Send To BaseStation:  <"req", "abc", member loc>

                    pusht location  // React to BS:  <"grl", leader loc>
                    pushn grl   // future:  <"grl", member ID, leader loc>
                    pushc 2   

                    in    // wait for response
                    //pushc 26
                    //putled
                    pop       // pop 2
                    pop       // pop grl
                    setvar 1  // heap[1] = leader location
    
// Register with the leader
                    loc
                    aid
                    pushn jng
                    pushc 3   // To Leader:  <"jng", member ID, member loc>
                    getvar 1
                    rout    // send to leader location

// register reaction: for leader broadcast messages
                    pusht string
                    pusht string
                    aid
                    pushn lbm // <"lbm", memeber ID, screen name, chat msg>
                    pushc 4
                    pushcl LEADER_MSG
                    regrxn

// register reaction: for messages from PDA+Proxy to send 
// FromPDA+Proxy:  <'ocm', screen name, chat msg>
                    pusht string
                    pusht string
                    pushn ocm
                    pushc 3
                    pushcl PDA_MSG
                    regrxn
    
// register reaction:  for member agent to follow PDA
// From Proxy:  <"mov", new loc>
                    pusht value
                    pushn mov
                    pushc 2
                    pushcl FOLLOW_PDA
                    regrxn
    

WAIT                wait
    
// React to:  <"lbm", memeber ID, screen name, chat msg>
// Send to Proxy:  
LEADER_MSG          remove      // remove the tuple
                    pop
                    pop
                    pop     //   Stack:  (screen name, chat msg)
                    getvar  0
                    cisnbr      // check if the PDA+Proxy is still a valid neighbor
                    rjumpc  LM_CONT
                    pop     //   fail, disgard chat msg
                    pop
                    endrxn
LM_CONT             pushn icm   // <"icm", screen name, chat msg>
                    pushc 3
                    getvar  0
                    rout      //   success, send tuple to PDA+Proxy
                    endrxn

// React to:  <'ocm', screen name, chat msg> from PDA+Proxy
// Send to leader:  <"mbm", AgentID, String:name, String:msg>
PDA_MSG             pushc 25
                    putled
                    remove
                    pop
                    pop     //  Stack:  (screen name, chat msg)
                    aid
                    pushn mbm
                    pushc 4     // <"mbm", AgentID, String:name, String:msg>
                    getvar 1
                    rout      // send to leader 
                    //pushc 26
                    //putled      // toggle green when message is sent to leader
                    endrxn

// register reaction:  for member agent to follow PDA
// From Proxy:  <"mov", new loc>
// To Leader:  <"upd", agentID, curr location>
FOLLOW_PDA          pushc 8
                    putled    // turn off all 3 LEDs
                    remove
                    pop
                    pop     //   Stack:  (new loc)
                    
                    copy
                    aid
                    pushn upd
                    pushc 3
                    getvar  1
                    rout        // send location update to the leader     
                    
                    smove
                    rjumpc FOLLOWSUCC
                    pushc 1
                    putled    // turn on red LED only if fail to move
                    halt            
FOLLOWSUCC          pushc 4   // turn on blue LED if successfully move
                    putled
                    endrxn         