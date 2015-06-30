//heap[0] = reserved location

pushc 26
putled
pushc 8
sleep
pushc 26
putled			// toggle the green LED

BEGIN pusht string
  pusht string
  pushn ocm   // react to PDA+Proxy msg
  pushc 3
  pushcl  PDA_MSG
  regrxn
  
  pusht string
  pusht string
  pushn lbm   // react to leader broadcast msg
  pushc 3
  pushcl  LEADER_MSG
  regrxn

WAIT wait

PDA_MSG remove       
  pop
  pop
  pushn lbm // translate into leader broadcast message
  pushc 3
  out		// for now just translate message into a leader broadcast message and send it
  endrxn
  
LEADER_MSG  remove
    pushc 26
    putled			// toggle green
    pop
    pop
    pushn icm // translate into in chat message
    pushc 3
    pushcl LM_RETURN
    pushcl GET_PROXY
    jumps
LM_RETURN rjumpc LM_SUCC
    pushc 25
	putled
	clear
	pushc WAIT
    endrxn
LM_SUCC   pushc 28		
          putled		// toggle blue led when proxy found
          rout
          endrxn

  
GET_PROXY numnbrs
GET_PROXY_LOOP  copy    //   Stack:  (# neighbor, # neighbor)
    pushc 0   
    ceq   //   Stack:  (# neighbor)
    rjumpc GET_PROXY_FAIL   // no more neighbor, fail
    dec
    copy    //   Stack:  (# neighbor -1, # neighbor -1)
    getnbr    
    copy    //   Stack:  (neighbor addr, neighbor addr, # neighbor -1)
    pushcl 65530
    clte    //   Stack:  (neighbor addr, # neighbor -1)
    rjumpc GET_PROXY_DONE   // find proxy addr, done
    pop   //   Stack:  (# neighbor -1)
    pushcl GET_PROXY_LOOP
    jumps
GET_PROXY_FAIL  pop       // no more neighbor, fail, condition=0, finish
    pushc 0
    cpull
    jumps
GET_PROXY_DONE  swap        
    pop   //   Stack:  (neighbor addr)
    swap    // put the return addr on top of stack
    pushc 1
    cpull
    jumps
