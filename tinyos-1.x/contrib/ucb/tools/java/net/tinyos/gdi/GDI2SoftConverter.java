package net.tinyos.gdi;

/**
 *
 * $Id: GDI2SoftConverter.java,v 1.2 2003/10/07 21:45:36 idgay Exp $
 */
public class GDI2SoftConverter {

    public static double humidity(int raw_humid) {
        double humidn = -4 + 0.0405*raw_humid +
            (-2.8 * Math.pow(10,-6) * Math.pow(raw_humid,2));
        return humidn;
    }

    public static double humid_temp(int raw_temp) {
        return (-38.4 + 0.0098 * raw_temp);
    }

    public static double humid_adj(int raw_humid, int raw_temp) {
        double temp = humid_temp(raw_temp);
        double humidn = humidity(raw_humid);
        double humidt = (temp - 25) * (0.01 + 0.00008*raw_humid) + humidn;
        return humidt;
    }

    public static double photo(int ch0, int ch1) {
        int s0 = ch0 & 0x0F;
        int cc0 = (ch0 >> 4) & 0x07;
        int s1 = ch1 & 0x0F;
        int cc1 = (ch1 >> 4) & 0x07;
        int adccount0 = ((int)(16.5 * ((Math.pow(2,cc0)-1)))
                 + ((int)(s0*Math.pow(2,cc0))));
        int adccount1 = ((int)(16.5 * ((Math.pow(2,cc1)-1)))
                 + ((int)(s1*Math.pow(2,cc1))));
        double lux = 0;
        try {
          lux = adccount0 * (0.46) * (Math.exp(-3.13*(adccount1/adccount0)));
        }
        catch (Exception e) {
            e.printStackTrace();
        }
        return lux;
    }

    public static double pressure_mbar(int raw_pressure, int raw_temperature, int[] calibration) {
        int c1,c2,c3,c4,c5,c6;
        if (calibration.length != 4)
            return 0;
        c1 = calibration[0] >> 1;
        c2 = calibration[2] & 0x3F;
        c2 <<= 6;
        c2 |= (calibration[3] & 0x3F);
        c3 = calibration[3] >> 6;
        c4 = calibration[2] >> 6;
        c5 = calibration[0] << 10;
        c5 &= 0x400;
        c5 += calibration[1] >> 6;
        c6 = calibration[1] & 0x3F;

        int ut1 = 8*c5+20224;
        int dt = raw_temperature - ut1;
        double temp = 200 + dt*(c6+50)/(Math.pow(2,10));

        double off = c2*4 + ((c4-512)*dt)/(Math.pow(2,12));
        double sens = c1 + (c3*dt)/(Math.pow(2,10)) + 24576;
        double x = (sens * (raw_pressure - 7168))/
            (Math.pow(2,14)) - off;
        double p = x*100/(Math.pow(2,5)) + 250*100;
			//System.out.println("Press (mbar) : " + p/100);
			//System.out.println("Press (inHg) : " + p/(100*33.864));
        return (p/100);
    }

    public static double pressure_inHg(int raw_pressure, int raw_temperature, int[] calibration) {
        int c1,c2,c3,c4,c5,c6;
        if (calibration.length != 4)
            return 0;
        c1 = calibration[0] >> 1;
        c2 = calibration[2] & 0x3F;
        c2 <<= 6;
        c2 |= (calibration[3] & 0x3F);
        c3 = calibration[3] >> 6;
        c4 = calibration[2] >> 6;
        c5 = calibration[0] << 10;
        c5 &= 0x400;
        c5 += calibration[1] >> 6;
        c6 = calibration[1] & 0x3F;

        int ut1 = 8*c5+20224;
        int dt = raw_temperature - ut1;

        double off = c2*4 + ((c4-512)*dt)/(Math.pow(2,12));
        double sens = c1 + (c3*dt)/(Math.pow(2,10)) + 24576;
        double x = (sens * (raw_pressure - 7168))/
            (Math.pow(2,14)) - off;
        double p = x*100/(Math.pow(2,5)) + 250*100;
        return (p/(100*33.864));
    }

    public static double pressure_temp(int raw_temperature, int[] calibration) {
        int c1,c2,c3,c4,c5,c6;
        if (calibration.length != 4)
            return 0;
        c1 = calibration[0] >> 1;
        c2 = calibration[2] & 0x3F;
        c2 <<= 6;
        c2 |= (calibration[3] & 0x3F);
        c3 = calibration[3] >> 6;
        c4 = calibration[2] >> 6;
        c5 = calibration[0] << 10;
        c5 &= 0x400;
        c5 += calibration[1] >> 6;
        c6 = calibration[1] & 0x3F;

        int ut1 = 8*c5+20224;
        int dt = raw_temperature - ut1;
        double temp = 200 + dt*(c6+50)/(Math.pow(2,10));
        return (temp/10);
    }

    public static double thermopile(int raw_thermopile) {
        double thermopile = (raw_thermopile >> 4);
        thermopile = ((thermopile*(120-(-20))) /
                  ((Math.pow(2,12))-1));
        thermopile += -20;
        return thermopile;
    }

    public static double thermistor(int raw_temperature) {
        double temperature = (raw_temperature >> 4);
        temperature = ((temperature*(85-(-20))) /
                  ((Math.pow(2,12))-1));
        temperature += -20;
        return temperature;
    }

    public static double voltage(int raw_voltage) {
        double temp = 0;
        try {
          temp = (0.58*1024)/raw_voltage;
        }
        catch (Exception e) {
          e.printStackTrace();
        }
        return temp;
    }

    public static byte[] toCalibByteArray(int[] words) {
        byte[] result = new byte[words.length*2];
        for (int i = 0; i < words.length; i++) {
            result[2*i] = (byte)(words[i] & 0x0FF);
            result[(2*i)+1] = (byte)((words[i+1] >> 8) & 0x0FF);
        }
        return result;
    }

    public static int[] fromCalibByteArray(byte[] input) {
        int[] result = new int[(input.length/2)];
        for (int i = 0; i < input.length; i = i+2) {
            result[(int)Math.floor(i/2)] = input[i];
            result[(int)Math.floor(i/2)] |= ((input[i+1] << 8) & 0xFF00);
        }
        return result;
    }
}
