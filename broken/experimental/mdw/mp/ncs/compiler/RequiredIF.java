package ncs.compiler;

public class RequiredIF {

  String ifname;
  String asifname;

  public RequiredIF(String ifname, String asifname) {
    this.ifname = ifname;
    if (asifname != null) {
      this.asifname = asifname;
    } else {
      this.asifname = ifname;
    }
  }
}
