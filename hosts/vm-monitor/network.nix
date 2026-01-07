let
  hostName = "vm-monitor";
in
{
  networking = {
    inherit hostName;
  };
}
