{
  description = "Native (non-Docker) macOS deployment of ollama + open-webui via services-flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs = inputs@{ flake-parts, process-compose-flake, services-flake, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      imports = [ process-compose-flake.flakeModule ];

      perSystem = { pkgs, lib, ... }: {
        # `nix run` starts the whole stack (process-compose TUI).
        process-compose."default" = {
          imports = [ services-flake.processComposeModules.default ];

          # --- ollama: nixpkgs package; Metal is automatic on Apple Silicon ---
          services.ollama."ollama" = {
            enable = true;
            # Reuse the existing repo-relative data layout (.data/ollama).
            dataDir = "./.data/ollama";
            host = "127.0.0.1";
            port = 11434;
            # acceleration = null -> auto-detect. On darwin, Metal needs no flag.
            # models = [ ];  # optionally auto-pull on startup
          };

          # --- open-webui: latest from PyPI via uvx (no clone, no Node build) ---
          settings.processes."open-webui" = {
            command = lib.getExe (pkgs.writeShellApplication {
              name = "open-webui-serve";
              runtimeInputs = [ pkgs.uv pkgs.git ];
              text = ''
                export DATA_DIR="''${PWD}/.data/open-webui"
                export OLLAMA_BASE_URL="http://127.0.0.1:11434"
                # Match the current single-user, empty-secret compose setup.
                export WEBUI_AUTH="False"
                exec uvx --python 3.11 open-webui@latest serve \
                  --host 0.0.0.0 --port "''${WEBUI_PORT:-3000}"
              '';
            });
            # Start only after ollama reports healthy (its built-in readiness probe).
            depends_on."ollama".condition = "process_healthy";
            readiness_probe = {
              http_get = {
                host = "127.0.0.1";
                port = 3000;
                path = "/health";
              };
              initial_delay_seconds = 5;
              period_seconds = 10;
              timeout_seconds = 4;
              failure_threshold = 30;
            };
          };
        };

        # Convenience shell: gives you `process-compose`, `uv`, `git`, `ollama` on PATH
        # for ad-hoc control (e.g. `process-compose process restart open-webui`).
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.process-compose pkgs.uv pkgs.git pkgs.ollama ];
        };
      };
    };
}
