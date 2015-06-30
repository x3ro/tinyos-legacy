configuration ClassifierC {
  provides interface Classifier;
  provides interface StdControl;
  }
  
implementation {
  components ClassifierM, EnergyEstimatorM, SignalDetectorM,
                MovingStatisticsM, MagSamplerM, TsyncC, TimerC, MagC, LedsC;

	
	StdControl = ClassifierM;
	StdControl = EnergyEstimatorM;
	StdControl = SignalDetectorM;
	StdControl = MovingStatisticsM;
	StdControl = MagSamplerM;
	StdControl = MagC;
  	Classifier = ClassifierM;

	ClassifierM.EnergyEstimator -> EnergyEstimatorM;
      ClassifierM.SignalDetector -> SignalDetectorM;
      ClassifierM.TsyncControl -> TsyncC.StdControl;     
      ClassifierM.OTime -> TsyncC;

    	EnergyEstimatorM.SignalDetector -> SignalDetectorM;
    	EnergyEstimatorM.MovingStatistics -> MovingStatisticsM;

	SignalDetectorM.MovingStatistics -> MovingStatisticsM;
    	SignalDetectorM.Leds -> LedsC;

    	MovingStatisticsM.MagSampler -> MagSamplerM;

	MagSamplerM.Timer -> TimerC.Timer[unique("Timer")];
    	MagSamplerM.MagSensor -> MagC;

}


