#include "StorageVolumes.h"

configuration FlashSamplerAppC { }
implementation
{
  components FlashSamplerC, SummarizerC, AccelSamplerC;
  components MainC, LedsC, new TimerMilliC(), 
    new LogStorageC(VOLUME_SAMPLELOG, TRUE),
    new BlockStorageC(VOLUME_SAMPLES),
    new AccelXStreamC();

  FlashSamplerC.Boot -> MainC;
  FlashSamplerC.Leds -> LedsC;
  FlashSamplerC.Timer -> TimerMilliC;
  FlashSamplerC.Summary -> SummarizerC;
  FlashSamplerC.Sample -> AccelSamplerC;

  AccelSamplerC.Accel -> AccelXStreamC;
  AccelSamplerC.BlockWrite -> BlockStorageC;
  AccelSamplerC.Leds -> LedsC;

  SummarizerC.BlockRead -> BlockStorageC;
  SummarizerC.LogWrite -> LogStorageC;
}
