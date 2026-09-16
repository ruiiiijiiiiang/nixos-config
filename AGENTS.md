# AI Agent Project Context: nixos-config

## Deployment and Build Rules

- **Explicitly Authorized Builds:** An AI agent must not run `nix build` or any other command that builds Nix derivations, locally or remotely, unless explicitly instructed to do so by the operator. Agents may run `nix eval` without separate authorization when inspecting attribute values and expressions.
- **Strictly Manual Deployments:** `nixos-rebuild`, deployment tools, and other commands that modify a running system must be performed manually by the operator. An instruction to build or test a configuration does not authorize its deployment.
- **Strict Investigation & Modification Flow:** When tasked to investigate an issue, the agent must always report findings first and present a proposed solution. Under no circumstances should the agent update any codebase or configuration files directly without receiving explicit manual confirmation from the user for the proposed changes.

## Development Conventions

### OCI Container Setup Convention

Containerized services must follow these repository conventions:

- **Centralized Constants:** Declare any new subdomains, ports, and unique container UIDs in [lib/consts.nix](file:///home/rui/nixos-config/lib/consts.nix).
- **User Provisioning:** Use `helpers.mkOciUser` in the module to define a dedicated system user/group with the declared OCI UID.
- **Directory Creation:** Use `systemd.tmpfiles.rules` to create required host storage directories, assigning ownership to the OCI UID/GID.
- **Secret Management:** Manage sensitive variables in agenix. Secret preparation and agenix decryption are always handled manually by the user.
- **Network & Port Bindings:** Keep container ports bound to `localhost` (e.g., `${addresses.localhost}:${toString ports.<name>}:<container-port>`) and expose them via Nginx. For sidecar setups, configure sidecars to use network dependencies (e.g., using `networks = [ "container:<main-container>" ]` so they reuse the main container's network namespace).
- **Reverse Proxy:** Set up Nginx virtual hosts using the `helpers.mkVirtualHost` template.
- **getEnabledServices Integration:** Add the service mapping to the `getEnabledServices` helper in [lib/helpers.nix](file:///home/rui/nixos-config/lib/helpers.nix) so that enabled services can be dynamically resolved on their respective hosts.
- **Native Module Options over `extraOptions`:** Whenever there is a need to add raw configuration flags to a container using `extraOptions`, always check if a native NixOS `virtualisation.oci-containers` module option exists (e.g., `hostname`, `user`, `workdir`) and prefer using the native option.

### Centralized Constants (`lib/consts.nix`)

All network addresses, VLAN IDs, ports, subdomains, and hardware metadata are centralized in `lib/consts.nix`. **Always refer to this file when adding or modifying services.**

### Helpers (`lib/helpers.nix`)

Common logic (e.g., Nginx virtual host templates, PCI address parsing, systemd timer generators) is located in `lib/helpers.nix`.

### Secret Management

Secrets are managed using `agenix` and stored as `.age` files in the `secrets/` directory. They are decrypted at runtime by the respective hosts using SSH host keys.

### Nix Coding Style Guidelines

To maintain configuration readability and clean Nix codebase structure, the following formatting styles must be adhered to:

- **Grouped Attribute Sets:** Attribute sets should be nested/grouped together whenever possible rather than using dot-separated paths.
  - _Preferred:_ `set = { opt1 = true; opt2 = true; };`
  - _Discouraged:_ `set.opt1 = true; set.opt2 = true;`
- **Use `inherit`:** Use the `inherit` keyword whenever possible to import variables into scopes or attribute sets.
- **`with` Keyword Threshold:** The `with` keyword should be used in scopes only when the imported namespace/attribute set is referenced **more than 5 times**.
- **Syntax Highlighting in Strings:** When writing non-Nix syntax (such as YAML, Bash, or JSON) inside a Nix string, always add a language comment (e.g., `/* yaml */`, `/* bash */`) in front of the string to ensure proper syntax highlighting in editors.
  - _Example:_ `settingsFile = pkgs.writeText "settings.yml" /* yaml */ ''...'';`
- **Code Formatting:** Always use `nixfmt` to clean up and format Nix code after editing.
