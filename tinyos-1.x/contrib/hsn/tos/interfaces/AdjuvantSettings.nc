/* provided by Adjuvant_Settings module, used by DSDV_SoI_Mettric,
   Mesh, EnergyMetric and TinyDBShim which has "special" notion */

includes WSN;

interface AdjuvantSettings {
   command void init();  // call only at init time
   event void enableSoI(bool ToF);
   event void enableAdjuvantNode(bool ToF);
   command uint16_t getAdjuvantValue();
   command bool amAdjuvantNode();
   command bool isServiceEnabled();
}
