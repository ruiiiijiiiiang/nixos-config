{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    ansible
    ansible-lint
    ansible-navigator
    molecule
    sshpass
  ];

  shellHook = ''
    echo "⚙️  Ansible Dev Env Loaded"
    exec fish -l
  '';
}
