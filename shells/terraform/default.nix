{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    terraform
    terraform-ls
    tflint
    terraform-docs
    pre-commit
  ];

  shellHook = ''
    echo "🏗️  Terraform Dev Env Loaded"
    exec fish -l
  '';
}
