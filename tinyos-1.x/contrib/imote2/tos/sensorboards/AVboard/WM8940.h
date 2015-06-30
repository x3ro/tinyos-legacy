/**
 * @author Robbie Adler
 **/

#ifndef __WM8940_H__
#define __WM8940_H__

#define SOFTWARERESET (0)


#define POWERMANAGEMENT1 (1)
//writing of POWERMANAGEMENT1
#define POWERMANAGEMENT1_VMID_OP_EN         (1<<8)
#define POWERMANAGEMENT1_LVLSHIFT_EN        (1<<7)
#define POWERMANAGEMENT1_AUXEN              (1<<6)
#define POWERMANAGEMENT1_PLLEN              (1<<5)
#define POWERMANAGEMENT1_MICBEN             (1<<4)
#define POWERMANAGEMENT1_BIASEN             (1<<3)
#define POWERMANAGEMENT1_BUFIOEN            (1<<2)
#define POWERMANAGEMENT1_VMIDSEL(_x)        ( (_x) & 0x3)
//reading of POWERMANAGEMENT1
#define POWERMANAGEMENT1_DEVICE_REVISION(_x)  ( ((_x) & 0x7)

#define POWERMANAGEMENT2 (2)
#define POWERMANAGEMENT2_BOOSTEN           (1<<4)
#define POWERMANAGEMENT2_INPPGAEN          (1<<2)
#define POWERMANAGEMENT2_ADCEN             (1)

#define POWERMANAGEMENT3 (3)
#define POWERMANAGEMENT3_MONOEN            (1<<7)
#define POWERMANAGEMENT3_SPKNEN            (1<<6)
#define POWERMANAGEMENT3_SPKPEN            (1<<5)
#define POWERMANAGEMENT3_MONOMIXEN         (1<<3)
#define POWERMANAGEMENT3_SPKMIXEN          (1<<2)
#define POWERMANAGEMENT3_DACEN             (1)
      

#define AUDIOINTERFACE (4)
#define AUDIOINTERFACE_LOUTR               (1<<9)
#define AUDIOINTERFACE_BCP                 (1<<8)
#define AUDIOINTERFACE_FRAMEP              (1<<7)
#define AUDIOINTERFACE_WL(_x)              ( ((_x) & 0x3) << 5)
#define AUDIOINTERFACE_FMT(_x)             ( ((_x) & 0x3) << 3)
#define AUDIOINTERFACE_DLRSWAP             (1<<2)
#define AUDIOINTERFACE_ALRSWAP             (1<<1)

#define COMPANDINGCONTROL (5)

#define CLOCKGENCONTROL (6)
#define CLOCKGENCONTROL_CLKSEL             (1<<8)
#define CLOCKGENCONTROL_MCLKDIV(_x)        ( ((_x) & 0x7) << 5)
#define CLOCKGENCONTROL_BCLKDIV(_x)        ( ((_x) & 0x7) << 2)
#define CLOCKGENCONTROL_MS                 (1)


#define ADDITIONALCONTROL (7)
#define ADDITIONALCONTROL_POB_CTRL         (1<<6)
#define ADDITIONALCONTROL_SOFT_START       (1<<5)
#define ADDITIONALCONTROL_TOGGLE           (1<<4)
#define ADDITIONALCONTROL_SR(_x)           ( ((_x) & 0x7) << 1)
#define ADDITIONALCONTROL_SLOWCLKEN        (1)

#define GPIOSTUFF (8)

#define CONTROLINTERFACE (9)

#define DACCONTROL (10)
#define DACCONTROL_DACMU                    (1<<6)
#define DACCONTROL_AMUTE                    (1<<2)
#define DACCONTROL_DACPOL                   (1)
					       

#define DACDIGITALVOLUME (11)
#define DACDIGITALVOLUME_DACVOL(_x) ( (_x) & 0x8)

#define ADCCONTROL (14)
#define ADCCONTROL_HPFEN                    (1<<8)
#define ADCCONTROL_HPFAPP                   (1<<7)
#define ADCCONTROL_HPFCUT(_x)               ( ((_x) & 0x7) << 4)
#define ADCCONTROL_ADCPOL                   (1)

#define ADCDIGITALVOLUME (15)
#define ADCDIGITALVOLUME_ADCVOL(_x)         ( (_x) & 0xFF

#define NOTCHFILTER1 (16)
#define NOTCHFILTER2 (17)
#define NOTCHFILTER3 (18)
#define NOTCHFILTER4 (19)
#define NOTCHFILTER5 (20)
#define NOTCHFILTER6 (21)
#define NOTCHFILTER7 (22)
#define NOTCHFILTER8 (23)

#define DACLIMITER1  (24)
#define DACLIMITER2  (25)

#define ALCCONTROL1  (32)
#define ALCCONTROL1_ALCSEL                    (1<<8)

#define ALCCONTROL2  (33)
#define ALCCONTROL3  (34)
#define NOISEGATE    (35)

#define PLLN (36)
#define PLL1 (37)
#define PLL2 (38)
#define PLL3 (39)

#define ALCCONTROL4  (42)

#define INPUTCTRL    (44)

#define INPUTCTRL_MBVSEL                      (1<<8)
#define INPUTCTRL_AUX2INPPGA                  (1<<2)
#define INPUTCTRL_MICN2INPPGA                 (1<<1)
#define INPUTCTRL_MICP2INPPGA                 (1)

#define INPPGAGAINCTRL (45)
#define INPPGAGAINCTRL_INPPGAZC              (1<<7)
#define INPPGAGAINCTRL_INPPGAMUTE            (1<<6)
#define INPPGAGAINCTRL_INPPGAVOL(_x)         ( (_x) & 0x3F)

#define ADCBOOSTCTRL (47)
#define ADCBOOSTCTRL_PGABOOST                 (1<<8)
#define ADCBOOSTCTRL_MICP2BOOSTVOL(_x)        ( ((_x) & 0x7) << 4)
#define ADCBOOSTCTRL_AUX2BOOSTVOL(_x)         ( ((_x) & 0x7))


#define OUTPUTCTRL  (49)

#define SPKMIXERCONTROL (50)
#define SPKMIXERCONTROL_AUX2SPK               (1<<5)
#define SPKMIXERCONTROL_BYP2SPK               (1<<1)
#define SPKMIXERCONTROL_DAC2SPK               (1)
						
#define SPKVOLUMECONTROL (54)
#define SPKVOLUMECONTROL_SPKATTN              (1<<8)
#define SPKVOLUMECONTROL_SPKZC                (1<<7)
#define SPKVOLUMECONTROL_SPKMUTE              (1<<6)
#define SPKVOLUMECONTROL_SPKVOL(_x)           ( (_x) & 0x3F)

#define MONOMIXERCONTROL (56)







#endif // __WM8940_H__
