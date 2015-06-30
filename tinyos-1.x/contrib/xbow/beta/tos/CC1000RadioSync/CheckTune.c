#include <stdio.h>

enum {
  IF = 150000,
  FREQ_MIN = 4194304,
  FREQ_MAX = 16751615
};

const uint32_t FRefTbl[9] = {2457600,
			     2106514,
			     1843200,
			     1638400,
			     1474560,
			     1340509,
			     1228800,
			     1134277,
			     1053257};

const uint16_t CorTbl[9] = {1213,
			    1416,
			    1618,
			    1820,
			    2022,
			    2224,
			    2427,
			    2629,
			    2831};

const uint16_t FSepTbl[9] = {0x1AA,
			     0x1F1,
			     0x238,
			     0x280,
			     0x2C7,
			     0x30E,
			     0x355,
			     0x39C,
			     0x3E3};

  uint32_t cc1000ComputeFreq(uint32_t desiredFreq) {
    uint32_t ActualChannel = 0;
    uint32_t RXFreq = 0, TXFreq = 0;
    int32_t Offset = 0x7fffffff;
    uint16_t FSep = 0;
    uint8_t RefDiv = 0;
    uint8_t i;

    for (i = 0; i < 9; i++) {

      uint32_t NRef = ((desiredFreq + IF));
      uint32_t FRef = FRefTbl[i];
      uint32_t Channel = 0;
      uint32_t RXCalc = 0, TXCalc = 0;
      int32_t  diff;

      NRef = ((desiredFreq + IF) << 2) / FRef;
      if (NRef & 0x1) {
 	NRef++;
      }

      if (NRef & 0x2) {
	RXCalc = 16384 >> 1;
	Channel = FRef >> 1;
      }

      NRef >>= 2;

      RXCalc += (NRef * 16384) - 8192;
      if ((RXCalc < FREQ_MIN) || (RXCalc > FREQ_MAX)) 
	continue;
    
      TXCalc = RXCalc - CorTbl[i];
      if ((TXCalc < FREQ_MIN) || (TXCalc > FREQ_MAX)) 
	continue;

      Channel += (NRef * FRef);
      Channel -= IF;

      diff = Channel - desiredFreq;
      if (diff < 0)
	diff = 0 - diff;

      if (diff < Offset) {
	RXFreq = RXCalc;
	TXFreq = TXCalc;
	ActualChannel = Channel;
	FSep = FSepTbl[i];
	RefDiv = i + 6;
	Offset = diff;
      }

    }

    if (RefDiv != 0) {

      
      printf("DesiredFreq(Hz)\tActualFreq(Hz)\tOffset(Hz)\tFREQA\t\tFREQB\t\tFSEP\tREFDIV\n");
      printf("%d\t",desiredFreq);
      printf("%d\t",ActualChannel);
      printf("%d\t\t",Offset);
      printf("0x%lx\t",RXFreq);
      printf("0x%lx\t",TXFreq);
      printf("0x%lx\t",FSep);
      printf("%d\n",RefDiv);

#if 0      
      // FREQA
      gCurrentParameters[0x3] = (uint8_t)((RXFreq) & 0xFF);  // LSB
      gCurrentParameters[0x2] = (uint8_t)((RXFreq >> 8) & 0xFF);
      gCurrentParameters[0x1] = (uint8_t)((RXFreq >> 16) & 0xFF);  // MSB
      // FREQB
      gCurrentParameters[0x6] = (uint8_t)((TXFreq) & 0xFF); // LSB
      gCurrentParameters[0x5] = (uint8_t)((TXFreq >> 8) & 0xFF);
      gCurrentParameters[0x4] = (uint8_t)((TXFreq >> 16) & 0xFF);  // MSB
      // FSEP
      gCurrentParameters[0x8] = (uint8_t)((FSep) & 0xFF);  // LSB
      gCurrentParameters[0x7] = (uint8_t)((FSep >> 8) & 0xFF); //MSB

      if (ActualChannel < 500000000) {
	if (ActualChannel < 400000000) {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((8 << CC1K_VCO_CURRENT) | (1 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((9 << CC1K_VCO_CURRENT) | (1 << CC1K_PA_DRIVE));
	}
	else {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((4 << CC1K_VCO_CURRENT) | (1 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((8 << CC1K_VCO_CURRENT) | (1 << CC1K_PA_DRIVE));
	}
	// FRONT_END
	gCurrentParameters[0xa] = (1 << CC1K_IF_RSSI); 
	// MATCH
	gCurrentParameters[0x12] = (7 << CC1K_RX_MATCH);
      }
      else {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((8 << CC1K_VCO_CURRENT) | (3 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((15 << CC1K_VCO_CURRENT) | (3 << CC1K_PA_DRIVE));

	// FRONT_END
	gCurrentParameters[0xa] = ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | 
				 (1<<CC1K_IF_RSSI));
	// MATCH
	gCurrentParameters[0x12] = (2 << CC1K_RX_MATCH);

      }
      // PLL
      gCurrentParameters[0xc] = (RefDiv << CC1K_REFDIV);
#endif
    }

    //gCurrentChannel = ActualChannel;
    return ActualChannel;

  }


int main(int argc, char **argv) {

  uint32_t DesiredFreq;
  uint32_t ActualFreq;

  if (argc < 2) {
    printf ("Usage: %s <frequency(Hz)>\n",argv[0]);
    return 0;
  }

  DesiredFreq = atoi(argv[1]);
  ActualFreq = cc1000ComputeFreq(DesiredFreq);

  return 0;

}
