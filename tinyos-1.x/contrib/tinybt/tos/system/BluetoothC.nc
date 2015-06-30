configuration BluetoothC
{
     provides {
          interface StdControl;
          interface Bluetooth;
     }
}
implementation
{
     components hciCoreC;
     StdControl = hciCoreC;
     Bluetooth = hciCoreC;
}
