/** Created: Robbie Adler
 *  Modified: Rahul Shah (Oct 15, 2005)
 *      - Changed some values so that they are valid C identifiers
 *  Modified: Phil Muse (Oct 22, 2005)
 *      - Changed name to UOM (UnitsOfMeasure)
 *  Modified: Phil Muse (Jul 20, 2006)
 *      - Added UOM_ENUM_COUNT as number of elements in enum for data 
 *        validation purposes in the gateway.
 *  Modified: Phil Muse (Aug 16, 2006)
 *      - Removed macro expansion and wrote code out long-hand
 **/

#ifndef UOM_ENUM_COUNT
#define UOM_ENUM_COUNT 87
#endif
enum UOM_t{
   	unknown,           
	ft,
	in,
	um,
	mils,
	microns,
	mm,
	ips,
	mm_sec,
	m_s,
	m_min,
	um_min,
	um_sec,
	ft_min,
	gs,
	m_s2,
	Amp,
	Amperage,
	bars,
	BOV,
	BTU,
	BTU_h,
	BTU_min,
	CFH,
	cfu_ml_log,
	count,
	CPM,
	deg_C,
	deg_F,
  	deg_K,
  	dynes,
  	Ergs,
  	fathoms,
  	ft_lb,
  	ft_lb_min,
	ft_lb_s,
	Gallons,
	gpm,
	hrs,
	Hz,
	Inches_H2O,
	inches_HG,
	J,
	J_s,
	kA,
	kg,
	kg_Cal,
	kg_Cal_min,
	kg_m,
	kg_cm2,
	Knots,
	kPa,
	kV,
	kva,
	kW,
	kWh,
	lbs,
	lbs_of_F,
	load,
	Loaded_Hours,
	Loaded_PSI,
	mA,
	min,
	minutes,
	Mohm,
	Moisture_PPM,
	mV,
	MW,
	N,
	Pa,
	Percent,
	pH,
	ppb,
	ppm,
	prtcls_mL,
	PSF,
	PSI,
	PSID,
	RPM,
	Torrs,
	Total_Acid_Number,
	uMhos,
	uS,
	uS_cm,
	V,
	Vdc,
	watts };		   

const char* UOM_tasString(int UOM)
{
  switch (UOM) {
  case 0: return "unknown";
  case 1: return "ft";
  case 2: return "in";
  case 3: return "um";
  case 4: return "mils";
  case 5: return "microns";
  case 6: return "mm";
  case 7: return "ips";
  case 8: return "mm_sec";
  case 9: return "m_s";
  case 10: return "m_min";
  case 11: return "um_min";
  case 12: return "um_sec";
  case 13: return "ft_min";
  case 14: return "gs";
  case 15: return "m_s2";
  case 16: return "Amp";
  case 17: return "Amperage";
  case 18: return "bars";
  case 19: return "BOV";
  case 20: return "BTU";
  case 21: return "BTU_h";
  case 22: return "BTU_min";
  case 23: return "CFH";
  case 24: return "cfu_ml_log";
  case 25: return "count";
  case 26: return "CPM";
  case 27: return "deg_C";
  case 28: return "deg_F";
  case 29: return "deg_K";
  case 30: return "dynes";
  case 31: return "Ergs";
  case 32: return "fathoms";
  case 33: return "ft_lb";
  case 34: return "ft_lb_min";
  case 35: return "ft_lb_s";
  case 36: return "Gallons";
  case 37: return "gpm"; 
  case 38: return "hrs";
  case 39: return "Hz";
  case 40: return "Inches_H2O";
  case 41: return "inches_HG";
  case 42: return "J";
  case 43: return "J_s";
  case 44: return "kA";
  case 45: return "kg";
  case 46: return "kg_Cal";
  case 47: return "kg_Cal_min";
  case 48: return "kg_m";
  case 49: return "kg_cm2";
  case 50: return "Knots";
  case 51: return "kPa";
  case 52: return "kV";
  case 53: return "kva";
  case 54: return "kW";
  case 55: return "kWh";
  case 56: return "lbs";
  case 57: return "lbs_of_F";
  case 58: return "load";
  case 59: return "Loaded_Hours";
  case 60: return "Loaded_PSI";
  case 61: return "mA";
  case 62: return "min";
  case 63: return "minutes";
  case 64: return "Mohm";
  case 65: return "Moisture_PPM";
  case 66: return "mV";
  case 67: return "MW";
  case 68: return "N";
  case 69: return "Pa";
  case 70: return "Percent";
  case 71: return "pH";
  case 72: return "ppb";
  case 73: return "ppm";
  case 74: return "prtcls_mL";
  case 75: return "PSF";
  case 76: return "PSI";
  case 77: return "PSID";
  case 78: return "RPM";
  case 79: return "Torrs";
  case 80: return "Total_Acid_Number";
  case 81: return "uMhos";
  case 82: return "uS";
  case 83: return "uS_cm";
  case 84: return "V";
  case 85: return "Vdc";
  case 86: return "watts";
  default: return "";
  }
}

int UOM_tfromString(char * UOM)
{
  if (strcmp(UOM, "unknown") == 0) {
    return 0;
  }
  if (strcmp(UOM, "ft") == 0) {
    return 1;
  }
  if (strcmp(UOM, "in") == 0) {
    return 2;
  }
  if (strcmp(UOM, "um") == 0) {
    return 3;
  }
  if (strcmp(UOM, "mils") == 0) {
    return 4;
  }
  if (strcmp(UOM, "microns") == 0) {
    return 5;
  }
  if (strcmp(UOM, "mm") == 0) {
    return 6;
  }
  if (strcmp(UOM, "ips") == 0) {
    return 7;
  }
  if (strcmp(UOM, "mm_sec") == 0) {
    return 8;
  }
  if (strcmp(UOM, "m_s") == 0) {
    return 9;
  }
  if (strcmp(UOM, "m_min") == 0) {
    return 10;
  }
  if (strcmp(UOM, "um_min") == 0) {
    return 11;
  }
  if (strcmp(UOM, "um_sec") == 0) {
    return 12;
  }
  if (strcmp(UOM, "ft_min") == 0) {
    return 13;
  }
  if (strcmp(UOM, "gs") == 0) {
    return 14;
  }
  if (strcmp(UOM, "m_s2") == 0) {
    return 15;
  }
  if (strcmp(UOM, "Amp") == 0) {
    return 16;
  }
  if (strcmp(UOM, "Amperage") == 0) {
    return 17;
  }
  if (strcmp(UOM, "bars") == 0) {
    return 18;
  }
  if (strcmp(UOM, "BOV") == 0) {
    return 19;
  }
  if (strcmp(UOM, "BTU") == 0) {
    return 20;
  }
  if (strcmp(UOM, "BTU_h") == 0) {
    return 21;
  }
  if (strcmp(UOM, "BTU_min") == 0) {
    return 22;
  }
  if (strcmp(UOM, "CFH") == 0) {
    return 23;
  }
  if (strcmp(UOM, "cfu_ml_log") == 0) {
    return 24;
  }
  if (strcmp(UOM, "count") == 0) {
    return 25;
  }
  if (strcmp(UOM, "CPM") == 0) {
    return 26;
  }
  if (strcmp(UOM, "deg_C") == 0) {
    return 27;
  }
  if (strcmp(UOM, "deg_F") == 0) {
    return 28;
  }
  if (strcmp(UOM, "deg_K") == 0) {
    return 29;
  }
  if (strcmp(UOM, "dynes") == 0) {
    return 30;
  }
  if (strcmp(UOM, "Ergs") == 0) {
    return 31;
  }
  if (strcmp(UOM, "fathoms") == 0) {
    return 32;
  }
  if (strcmp(UOM, "ft_lb") == 0) {
    return 33;
  }
  if (strcmp(UOM, "ft_lb_min") == 0) {
    return 34;
  }
  if (strcmp(UOM, "ft_lb_s") == 0) {
    return 35;
  }
  if (strcmp(UOM, "Gallons") == 0) {
    return 36;
  }
  if (strcmp(UOM, "gpm") == 0) {
    return 37;
  }
  if (strcmp(UOM, "hrs") == 0) {
    return 38;
  }
  if (strcmp(UOM, "Hz") == 0) {
    return 39;
  }
  if (strcmp(UOM, "Inches_H2O") == 0) {
    return 40;
  }
  if (strcmp(UOM, "inches_HG") == 0) {
    return 41;
  }
  if (strcmp(UOM, "J") == 0) {
    return 42;
  }
  if (strcmp(UOM, "J_s") == 0) {
    return 43;
  }
  if (strcmp(UOM, "kA") == 0) {
    return 44;
  }
  if (strcmp(UOM, "kg") == 0) {
    return 45;
  }
  if (strcmp(UOM, "kg_Cal") == 0) {
    return 46;
  }
  if (strcmp(UOM, "kg_Cal_min") == 0) {
    return 47;
  }
  if (strcmp(UOM, "kg_m") == 0) {
    return 48;
  }
  if (strcmp(UOM, "kg_cm2") == 0) {
    return 49;
  }
  if (strcmp(UOM, "Knots") == 0) {
    return 50;
  }
  if (strcmp(UOM, "kPa") == 0) {
    return 51;
  }
  if (strcmp(UOM, "kV") == 0) {
    return 52;
  }
  if (strcmp(UOM, "kva") == 0) {
    return 53;
  }
  if (strcmp(UOM, "kW") == 0) {
    return 54;
  }
  if (strcmp(UOM, "kWh") == 0) {
    return 55;
  }
  if (strcmp(UOM, "lbs") == 0) {
    return 56;
  }
  if (strcmp(UOM, "lbs_of_F") == 0) {
    return 57;
  }
  if (strcmp(UOM, "load") == 0) {
    return 58;
  }
  if (strcmp(UOM, "Loaded_Hours") == 0) {
    return 59;
  }
  if (strcmp(UOM, "Loaded_PSI") == 0) {
    return 60;
  }
  if (strcmp(UOM, "mA") == 0) {
    return 61;
  }
  if (strcmp(UOM, "min") == 0) {
    return 62;
  }
  if (strcmp(UOM, "minutes") == 0) {
    return 63;
  }
  if (strcmp(UOM, "Mohm") == 0) {
    return 64;
  }
  if (strcmp(UOM, "Moisture_PPM") == 0) {
    return 65;
  }
  if (strcmp(UOM, "mV") == 0) {
    return 66;
  }
  if (strcmp(UOM, "MW") == 0) {
    return 67;
  }
  if (strcmp(UOM, "N") == 0) {
    return 68;
  }
  if (strcmp(UOM, "Pa") == 0) {
    return 69;
  }
  if (strcmp(UOM, "Percent") == 0) {
    return 70;
  }
  if (strcmp(UOM, "pH") == 0) {
    return 71;
  }
  if (strcmp(UOM, "ppb") == 0) {
    return 72;
  }
  if (strcmp(UOM, "ppm") == 0) {
    return 73;
  }
  if (strcmp(UOM, "prtcls_mL") == 0) {
    return 74;
  }
  if (strcmp(UOM, "PSF") == 0) {
    return 75;
  }
  if (strcmp(UOM, "PSI") == 0) {
    return 76;
  }
  if (strcmp(UOM, "PSID") == 0) {
    return 77;
  }
  if (strcmp(UOM, "RPM") == 0) {
    return 78;
  }
  if (strcmp(UOM, "Torrs") == 0) {
    return 79;
  }
  if (strcmp(UOM, "Total_Acid_Number") == 0) {
    return 80;
  }
  if (strcmp(UOM, "uMhos") == 0) {
    return 81;
  }
  if (strcmp(UOM, "uS") == 0) {
    return 82;
  }
  if (strcmp(UOM, "uS_cm") == 0) {
    return 83;
  }
  if (strcmp(UOM, "V") == 0) {
    return 84;
  }
  if (strcmp(UOM, "Vdc") == 0) {
    return 85;
  }
  if (strcmp(UOM, "watts") == 0) {
    return 86;
  }

  return 0;
}

