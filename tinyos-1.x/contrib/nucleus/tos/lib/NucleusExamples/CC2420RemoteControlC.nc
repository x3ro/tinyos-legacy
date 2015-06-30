configuration CC2420RemoteControlC {
}
implementation {
  components CC2420RemoteControlM, CC2420RadioC;

  CC2420RemoteControlM.CC2420Control -> CC2420RadioC;
  CC2420RemoteControlM.MacControl -> CC2420RadioC;
}
