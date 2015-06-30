/*
 * PIRINITTIME is the delay in second to sample PIR sensors after the 
 * physical PIR sensor is powered, i.e. started. It takes PIRINITTIME 
 * seconds for the PIR readings to be stable after the sensor is powered.
 */
#ifdef PLATFORM_PC
// In simulation, we don't wait at all since all the readings are
// presumably taken after the PIR has warmed up. -mpm
#define PIRINITTIME 0
#else
#define PIRINITTIME 500
#endif

/*
 * PIRSAMPLEPERIOD is the period (in binary milliseconds) between
 * samples for PIR sensors.
 */
#define PIRSAMPLEPERIOD 102


////////// Lowpass/Highpass Filter //////////
/*
 * FILTSETTLE is the number of delays in samples to use PIR sensor 
 * readings after the PIR sensor is enabled. Enabling the PIR sensor
 * is starting a sampling timer for the sensor.
 */
#define FILTSETTLE 10

/*
 * In the PIR processing module, a pass filter is used to filter
 * out noises of low frequency and a low pass filter to filter out
 * noises of high frequency. We use ARMA model to describe both
 * filters. HIGHPASSMAORDER and HIGHPASSARORDER define the order
 * of MA and AR parts in the high pass filter, respectively. 
 * LOWPASSMAORDER and LOWPASSARORDER define the order of MA and
 * AR parts in the low pass filter.
 */
#define HIGHPASSMAORDER 1
#define HIGHPASSARORDER 1

#define LOWPASSMAORDER 1
#define LOWPASSARORDER 1


////////// Adaptive Threshold //////////
/*
 * PIRMINTHRESH is the minimal value for the threshold value
 * of PIR signal energy (i.e. energyPIR) within certain time 
 * window (i.e. ENERGYWINDOW) to identify a movement.
 */
// 60 seems too high, let's try 40 -mpm
//#define PIRMINTHRESH 60 
#define PIRMINTHRESH 40 

/* 
 * PIRADAPTTHRESHPERIOD is the number of binary milliseconds (1/1024
 * sec) before the adaptive threshold is updated.
 */
#define PIRADAPTTHRESHPERIOD 5*1024

/*
 * ADAPTATIONWEIGHTOLD and ADAPTATIONWEIGHTNEW are weight to update
 * the threshold value:
 * new threshold = (ADAPTATIONWEIGHTOLD * old threshold + ADAPTATIONWEIGTNEW
 *                  * updating value) / (ADAPTATIONWEIGHTNEW + ADAPTATIONWEIGHTNEW)
 */
#define UPADAPTATIONWEIGHTOLD 98
#define UPADAPTATIONWEIGHTNEW 2
#define DOWNADAPTATIONWEIGHTOLD 75
#define DOWNADAPTATIONWEIGHTNEW 25


////////// Detection //////////
/*
 * ENERGYWINDOW is the number of data to compute signal energy.
 */
#define ENERGYWINDOW 1

/*
 * CONFIDENCEWINDOWS is the number of history readings to generate
 * the confidence vector.
 */
#define CONFIDENCEWINDOW 10

/*
 * detection means >= MOTIONTHRESHOLD percent of the last 
 * CONFIDENCEWINDOW number of reports must be hits.
 */
#define CONFIDENCETHRESH 40

/*
 * PIRREPDAMPING is the number of sampling periods before reporting
 * the detection result after the last report if the confidence
 * does not have a big jump.
 */
//#define PIRREPDAMPING 20
// For now I want to always report a confidence, so this is 1 (i.e.
// we don't damp).
#define PIRREPDAMPING 1

/*
 * The change in total confidence larger than SUDDENJUMP is
 * a significant change to trigger a instantaneous report.
 */
#define SUDDENJUMP 20


// Do we need to define these macros?
#define max(x1,x2) (x1 > x2) ? x1 : x2
#define min(x1,x2) (x1 < x2) ? x1 : x2
#define abs(x) (x > 0) ? x : -x
