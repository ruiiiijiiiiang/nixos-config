let
  hostName = "vm-network";
in
{
  networking = {
    inherit hostName;
  };
}
