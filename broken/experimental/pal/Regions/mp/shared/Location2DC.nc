
configuration Location2DC {
  provides interface Location2D;
} implementation {
  components FakeLocation, Location2DM;

  Location2D = Location2DM;
  Location2DM.Location -> FakeLocation;

}

