{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) hostName;
  cfg = config.custom.services.infra.protondrive;

  serviceName = "proton-drive-upload";
  serviceUser = serviceName;
  stateDirectory = "/var/lib/${serviceName}";
  runtimeDirectory = "${stateDirectory}/runtime";
  uploadDefinitions = lib.attrValues cfg.uploads;
  sourcePaths = lib.concatMap (upload: upload.sourcePaths) uploadDefinitions;
  remotePathFor = upload: "${cfg.remoteRoot}/${upload.remotePath}";
  validRemotePath =
    path:
    let
      components = lib.splitString "/" path;
    in
    components != [ ]
    && lib.all (
      component:
      !builtins.elem component [
        ""
        "."
        ".."
      ]
    ) components;
  uploadCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: upload:
      "upload ${lib.escapeShellArg name} "
      + lib.escapeShellArg (builtins.toJSON upload.ignoredFailures)
      + " "
      + lib.concatMapStringsSep " " lib.escapeShellArg upload.sourcePaths
      + " ${lib.escapeShellArg (remotePathFor upload)}"
    ) cfg.uploads
  );

  # renovate: datasource=custom.proton-drive depName=proton-drive versioning=semver
  proton-drive-version = "0.7.0";
  proton-drive-sha512 = "5a5affcbec04ea926a32d10e236c1342227f1b6d416cb797f88f943b2c4f1dcf53b5897a115f1c1aa9ce8ce92fd637e1c50bd223b04866577681f0584eccdbc6";

  proton-drive = pkgs.stdenvNoCC.mkDerivation {
    pname = "proton-drive";
    version = proton-drive-version;

    src = pkgs.fetchurl {
      url = "https://proton.me/download/drive/cli/${proton-drive-version}/linux-x64/proton-drive";
      sha512 = proton-drive-sha512;
    };

    dontUnpack = true;
    # Bun standalone executables contain layout-dependent embedded payloads.
    dontFixup = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = /* bash */ ''
      runHook preInstall
      install -Dm755 "$src" "$out/libexec/proton-drive"
      makeWrapper ${pkgs.stdenv.cc.bintools.dynamicLinker} "$out/bin/proton-drive" \
        --add-flags "--library-path" \
        --add-flags ${lib.escapeShellArg (lib.makeLibraryPath [ pkgs.glibc ])} \
        --add-flags "$out/libexec/proton-drive"
      runHook postInstall
    '';

    meta = {
      description = "Official command-line interface for Proton Drive";
      homepage = "https://github.com/ProtonDriveApps/sdk/tree/main/cli";
      license = lib.licenses.gpl3Only;
      mainProgram = "proton-drive";
      platforms = [ "x86_64-linux" ];
    };
  };

  environment = {
    GNUPGHOME = "${stateDirectory}/gnupg";
    HOME = stateDirectory;
    PASSWORD_STORE_DIR = "${stateDirectory}/password-store";
    PROTON_DRIVE_CACHE_DIR = runtimeDirectory;
    PROTON_DRIVE_CREDENTIALS_STORE = "pass";
    PROTON_DRIVE_LOG_LEVEL = "INFO";
  };

  runtimePath = lib.makeBinPath [
    pkgs.coreutils
    pkgs.gnupg
    pkgs.pass
  ];

  credentialStoreSetup = pkgs.writeShellApplication {
    name = "${serviceName}-credential-store-setup";
    runtimeInputs = [
      pkgs.gawk
      pkgs.gnupg
      pkgs.pass
    ];
    text = /* bash */ ''
      if [[ -f "$PASSWORD_STORE_DIR/.gpg-id" ]]; then
        exit 0
      fi

      identity="${serviceName}@${hostName}"
      fingerprint="$(
        gpg --batch --with-colons --list-secret-keys "$identity" 2>/dev/null |
          awk -F: '$1 == "fpr" { print $10; exit }' ||
          true
      )"

      if [[ -z "$fingerprint" ]]; then
        gpg --batch \
          --pinentry-mode loopback \
          --passphrase "" \
          --quick-generate-key "$identity" default default never
        fingerprint="$(
          gpg --batch --with-colons --list-secret-keys "$identity" |
            awk -F: '$1 == "fpr" { print $10; exit }'
        )"
      fi

      if [[ -z "$fingerprint" ]]; then
        echo "Unable to create the GPG key used by the pass credential store" >&2
        exit 1
      fi

      pass init "$fingerprint"
    '';
  };

  managedCli = pkgs.writeShellApplication {
    name = "${serviceName}-managed-cli";
    runtimeInputs = [
      credentialStoreSetup
      proton-drive
    ];
    text = /* bash */ ''
      ${lib.getExe credentialStoreSetup}
      exec proton-drive "$@"
    '';
  };

  uploadScript = pkgs.writeShellApplication {
    name = serviceName;
    runtimeInputs = [
      proton-drive
      pkgs.gnupg
      pkgs.jq
      pkgs.pass
    ];
    text = /* bash */ ''
      status=0

      upload() {
        local label="$1"
        local ignored_failures="$2"
        local summary
        local summary_file
        shift 2

        echo "Uploading $label originals to Proton Drive"
        summary_file="$(mktemp)"
        if proton-drive filesystem upload \
          --json \
          --folder-conflict-strategy merge \
          --file-conflict-strategy merge \
          --skip-thumbnails \
          "$@" | tee "$summary_file"; then
          rm -f "$summary_file"
          return
        fi

        summary="$(
          jq -Rsc \
            '[split("\n")[] | fromjson? | select(type == "object" and has("failures"))] | last' \
            "$summary_file"
        )"
        rm -f "$summary_file"

        if [[ "$summary" != "null" ]] &&
          printf '%s\n' "$summary" | jq --exit-status \
            --argjson ignored "$ignored_failures" \
            '(.failedItems > 0)
              and ((.failures | length) == .failedItems)
              and all(
                .failures[];
                . as $failure
                | any(
                    $ignored[];
                    . as $rule
                    | ($failure.name | test($rule.filePattern))
                      and ($failure.error | test($rule.errorPattern))
                  )
              )' >/dev/null; then
          echo "Ignoring expected $label upload failures:" >&2
          printf '%s\n' "$summary" | jq --raw-output \
            '.failures[] | "  - \(.name): \(.error)"' >&2
          return
        fi

        echo "Failed to upload $label originals" >&2
        status=1
      }

      ${uploadCommands}

      exit "$status"
    '';
  };

  adminCli = pkgs.writeShellApplication {
    name = "${serviceName}-cli";
    runtimeInputs = [ pkgs.util-linux ];
    text = /* bash */ ''
      if (( EUID != 0 )); then
        echo "Run this command with sudo so it can switch to ${serviceUser}" >&2
        exit 1
      fi

      cd ${lib.escapeShellArg stateDirectory}
      exec runuser --user ${serviceUser} -- env -i \
        GNUPGHOME=${lib.escapeShellArg environment.GNUPGHOME} \
        HOME=${lib.escapeShellArg environment.HOME} \
        PASSWORD_STORE_DIR=${lib.escapeShellArg environment.PASSWORD_STORE_DIR} \
        PATH=${lib.escapeShellArg runtimePath} \
        PROTON_DRIVE_CACHE_DIR=${lib.escapeShellArg environment.PROTON_DRIVE_CACHE_DIR} \
        PROTON_DRIVE_CREDENTIALS_STORE=${lib.escapeShellArg environment.PROTON_DRIVE_CREDENTIALS_STORE} \
        PROTON_DRIVE_LOG_LEVEL=${lib.escapeShellArg environment.PROTON_DRIVE_LOG_LEVEL} \
        ${lib.getExe managedCli} "$@"
    '';
  };
in
{
  options.custom.services.infra.protondrive = with lib; {
    enable = mkEnableOption "Enable original-file uploads to Proton Drive";
    schedule = mkOption {
      type = types.str;
      description = "Systemd calendar expression controlling original-file uploads.";
      example = "Mon *-*-* 06:00:00";
    };
    remoteRoot = mkOption {
      type = types.str;
      default = "/my-files/backup/files";
      description = "Existing Proton Drive directory under which contributed uploads are stored.";
    };
    uploads = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            sourcePaths = mkOption {
              type = types.listOf types.str;
              description = "Absolute local paths uploaded to this destination.";
            };
            remotePath = mkOption {
              type = types.str;
              description = "Destination path relative to remoteRoot.";
            };
            ignoredFailures = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    filePattern = mkOption {
                      type = types.str;
                      description = "Regular expression matching an expected failed filename.";
                    };
                    errorPattern = mkOption {
                      type = types.str;
                      description = "Regular expression matching the expected upload error.";
                    };
                  };
                }
              );
              default = [ ];
              description = "Upload failures that do not make this upload definition fail.";
            };
          };
        }
      );
      default = { };
      description = "Original-file upload definitions contributed by enabled service modules.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.uploads != { };
        message = "custom.services.infra.protondrive.uploads must contain at least one upload definition.";
      }
      {
        assertion = lib.hasPrefix "/my-files/" cfg.remoteRoot;
        message = "custom.services.infra.protondrive.remoteRoot must be below /my-files.";
      }
      {
        assertion = lib.all (
          upload: upload.sourcePaths != [ ] && lib.all (lib.hasPrefix "/") upload.sourcePaths
        ) uploadDefinitions;
        message = "Each Proton Drive upload must contain at least one absolute source path.";
      }
      {
        assertion = lib.all (upload: validRemotePath upload.remotePath) uploadDefinitions;
        message = "Each Proton Drive upload remotePath must be a safe relative path.";
      }
    ];

    environment.systemPackages = [ adminCli ];

    users = {
      groups.${serviceUser} = { };
      users.${serviceUser} = {
        isSystemUser = true;
        group = serviceUser;
        home = stateDirectory;
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d ${stateDirectory} 0700 ${serviceUser} ${serviceUser} - -"
        "d ${environment.GNUPGHOME} 0700 ${serviceUser} ${serviceUser} - -"
        "d ${environment.PASSWORD_STORE_DIR} 0700 ${serviceUser} ${serviceUser} - -"
        "d ${runtimeDirectory} 0700 ${serviceUser} ${serviceUser} - -"
      ];

      services.${serviceName} = {
        description = "Upload original application files to Proton Drive";
        after = [
          "network-online.target"
          "restic-backups-data-proton.service"
        ];
        wants = [ "network-online.target" ];
        inherit environment;

        unitConfig = {
          RequiresMountsFor = sourcePaths;
        };

        serviceConfig = {
          Type = "oneshot";
          User = serviceUser;
          Group = serviceUser;
          ExecStart = lib.getExe uploadScript;

          StateDirectory = serviceName;
          StateDirectoryMode = "0700";
          UMask = "0077";

          AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
          CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
          NoNewPrivileges = true;

          LockPersonality = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";

          IOSchedulingClass = "idle";
          Nice = 10;
          TimeoutStartSec = "infinity";
        };
      };

      timers.${serviceName} = {
        description = "Scheduled original-file upload to Proton Drive";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
          RandomizedDelaySec = 0;
          DeferReactivation = true;
        };
      };
    };

    custom.services.infra.restic.extraExcludes = lib.mkIf config.custom.services.infra.restic.enable [
      runtimeDirectory
    ];
  };
}
