
module ExecC {
  provides {
    interface Exec;
  }
}

implementation {
  
  command void Exec.exec() {
    
    WDTCTL = WDT_ARST_1000;
    
    if ( *(uint16_t*)0x4800 == 0x40b2 && // instruction
	 *(uint16_t*)0x4802 == 0x5a80 && // value
	 *(uint16_t*)0x4804 == 0x0120 )  // WDTCTL
      
      __asm__ __volatile__ ("br #0x4806\n\t" ::);
    
    else
      
      __asm__ __volatile__ ("br #0x4800\n\t" ::);
    
  }

}
