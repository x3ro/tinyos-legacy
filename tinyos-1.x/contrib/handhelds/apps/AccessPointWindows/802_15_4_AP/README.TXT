HOW TO USE THIS INITIAL VERSION
(until we have a friendly installer)


1. INSTALL TAP-WIN32 DRIVER

a) very easy way - install / use OpenVPN 2.1 rc7 or newer from
http://openvpn.net/
(if you already have that installed and you do not use it at the
same time as the 802.15.4 AP you can just start using it without
doing anything else - just make sure the adapter is enabled);

b) more technical way (also needed if you already USE OpenVPN and
you need a second / third TAP-Win32  adapter) - goto
Control Panel -> Add Hardware , select "Yes, it is already connected",
select last option = "Add a new hardware device", select "Install
hardware that I manually select from a list (Advanced)", then
"Show all devices", then "Have Disk" and "Browse" to the folder
called DRIVER and the file OemWin2k.inf - a new TAP-Win32 adapter
should appear in your Network Connections !



2. CONFIGURE THE TAP-WIN32 ADAPTER
(right-click on it in Network Connections -> Properties)

a) on the adapter /driver part (top "Configure" button), on the
"Advanced" tab - set MTU to 117

b) on the TCP/IP properties set the desired IP address
(this should be the same IP configured when compiling
AccessPointApp in TinyOS - IMHO a separate class than your
'normal adapters' - something like 192.168.154.1
or 10.15.4.1 for the AP and the rest of the range
for the other devices.



3. CONFIGURE the user-mode 802154ap program using AP_CFG.EXE !
(select the TAP device in the combo from the top and enter
the COM port in the corresponding field, then press SAVE).


4. RUN the user-mode 802154ap program - AP_CON.EXE !