{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.platforms.cloud.aws;
in
{
  options.custom.platforms.cloud.aws.enable = lib.mkEnableOption "Enable AWS platform settings";

  config = lib.mkIf cfg.enable {
    services.amazon-ssm-agent.enable = true;
  };
}
