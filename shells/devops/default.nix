{ pkgs }:

pkgs.mkShell {
  name = "devops-env";

  buildInputs = with pkgs; [
    ansible
    sshpass
    kubectl
    kubernetes-helm
    k9s

    (python3.withPackages (ps: with ps; [
      kubernetes
      requests
      jsonpatch
    ]))
  ];

  shellHook = ''
    exec fish -l
    echo "🛠️  DevOps Lab Environment Loaded"
    export KUBECONFIG=$PWD/kubeconfig
  '';
}
