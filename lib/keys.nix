{
  ssh = {
    rui-arch = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsyTs7DiG/Emm8B/fPqDh5LIEc+1V7DkF/ICIxPy68O me@ruijiang.me"
    ];
    rui-nixos = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9m3eaPWXrwynrF4hS5Llwfxm/FpNMjgoz41WnNfCUg me@ruijiang.me"
    ];
    rui-nixos-pi = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIJNc2DNOvGnp388Mr2WNYa4/pUq/kbyrpTJkc5Q8Oe raspberry-pi4"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4UQIyLo0sqjKZjBAPD/G3xHy/qT4DlbF34J5krTKBn root@rui-nixos-pi"
    ];
  };

  wg = {
    wg-home = {
      publicKey = "WTLUHiI8rWYnE4eXEZwYzMNmrarNKnZU9v9+CmgBCXA=";
    };
  };
}
