/** 
 *@Author Robbie Adler
 **/

configuration TestAVboard {
}

implementation {
  components Main, WM8940C, TestAVboardM;
  
  Main.StdControl -> TestAVboardM;
  TestAVboardM.CodecControl -> WM8940C.StdControl;
  TestAVboardM.Audio -> WM8940C.Audio;
}

