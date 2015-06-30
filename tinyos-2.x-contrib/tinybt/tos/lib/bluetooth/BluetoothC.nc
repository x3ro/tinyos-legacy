/**
 *
 * $Rev:: 48          $:  Revision of last commit
 * $Author: sengg $:  Author of last commit
 * $Date: 2011/12/09 19:48:58 $:  Date of last commit
 *
 **/
configuration BluetoothC
{
     provides {
          interface Bluetooth;
     }
}
implementation
{
     components HCICoreC;
     Bluetooth = HCICoreC.Bluetooth;
}
