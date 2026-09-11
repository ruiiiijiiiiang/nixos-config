{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    ansible
    ansible-lint
    molecule
    sshpass
  ];

  shellHook = ''
    echo "⚙️  Ansible Dev Env Loaded"
    exec fish -l
  '';
}
