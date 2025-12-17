{
  ssh = {
    rui-arch = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsyTs7DiG/Emm8B/fPqDh5LIEc+1V7DkF/ICIxPy68O me@ruijiang.me"
    ];
    framework = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9m3eaPWXrwynrF4hS5Llwfxm/FpNMjgoz41WnNfCUg me@ruijiang.me"
    ];
    pi = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIJNc2DNOvGnp388Mr2WNYa4/pUq/kbyrpTJkc5Q8Oe raspberry-pi4"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4UQIyLo0sqjKZjBAPD/G3xHy/qT4DlbF34J5krTKBn root@rui-nixos-pi"
    ];
    vm-network = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAZBzyGnYs0UkG7IxaAM1hvaFQ5XH736AHSGBkLWFa2n rui@rui-nixos-vm-network"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7ngRbvBzXV7amObcv4d/Cv0wzaZSBUGAyN1v1TqbRf root@rui-nixos-vm-network"
    ];
    vm-app = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7iFfDzcj1WCDIKvT5xD6jw7yYGSQ/vAZQ9cU15jXTt rui@rui-nixos-vm-app"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcmO69K4CBR/q3EUhNea+gaY3K6nfnMn3HbyvXLbFB7 root@rui-nixos-vm-app"
    ];
    github-action = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXXmiNdwQD1JdRzZYP2nKb6vR7ZxFxPhSQnJVgG1Dpm github-action"
    ];
  };

  wg = {
    wg-home = {
      publicKey = "WTLUHiI8rWYnE4eXEZwYzMNmrarNKnZU9v9+CmgBCXA=";
    };
  };
}
