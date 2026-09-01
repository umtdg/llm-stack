{
  description = "LLM stack deployment";

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
        process-compose."default" = {
          imports = [ services-flake.processComposeModules.default ];

          settings.processes."llama-server" = {
            command = ''
              exec ${lib.getExe' pkgs.llama-cpp "llama-server"} \
                --models-preset ${./models.ini} \
                --models-max 1 \
                --host 127.0.0.1 \
                --port 8080
            '';

            readiness_probe = {
              http_get = {
                host = "127.0.0.1";
                port = 8080;
                path = "/health";
              };

              initial_delay_seconds = 5;
              period_seconds = 4;
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.process-compose pkgs.uv pkgs.git pkgs.llama-cpp ];
        };
      };
    };
}
