let
  consts = import ../lib/consts.nix;
in
{
  awsEdge = {
    aws_region = consts.cloud.aws.region;
    alert_email = consts.email;
    availability_zone = consts.cloud.aws.availability-zone;
    vpc_cidr = consts.cloud.aws.edge-vpc-cidr;
    nixos_ami_name_pattern = consts.cloud.aws.nixos-ami-name-pattern;
    bootstrap_operator_cidr = null;
    bootstrap_ssh_enabled = false;
  };

  cloudflareDns = {
    cloudflare_zone_id = consts.cloud.cloudflare.zone-id;
  };

  githubRepository = {
    aws_account_id = consts.cloud.aws.account-id;
    cloudflare_zone_id = consts.cloud.cloudflare.zone-id;
  };
}
