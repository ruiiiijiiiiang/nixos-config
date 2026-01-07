let
  hostName = "vm-app";
in
{
  networking = {
    inherit hostName;
  };
}
