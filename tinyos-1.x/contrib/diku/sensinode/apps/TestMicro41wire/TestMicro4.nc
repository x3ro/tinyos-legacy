configuration TestMicro4 {

}
implementation {
	components Main,TestMicro4M, 
		StdOutC,
		HPL1wireM;

	Main.StdControl -> TestMicro4M.StdControl;

	TestMicro4M.StdOut -> StdOutC.StdOutUart;
	TestMicro4M.HPL1wire -> HPL1wireM.HPL1wire;


}

