#ifndef H_longwait_h
#define H_longwait_h

void longwait( uint16_t t ) {
  for( ; t > 0; t-- )
    wait(0xffff);
}

#endif

