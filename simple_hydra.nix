let
  host-name = "example.org";
in
{
  my-hydra = 
    { config, pkgs, ...}: {
      services.postfix = {
        enable = true;
        setSendmail = true;
      };
# programs.ssh.extraConfig = ''
#     StrictHostKeyChecking no
#   '';
  #   programs.ssh = {
  #   knownHosts."github.com".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==";
  # };
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/ssh.nix#L65
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql;
        identMap = ''
            hydra-users hydra hydra
            hydra-users hydra-queue-runner hydra
            hydra-users hydra-www hydra
            hydra-users root postgres
            hydra-users postgres postgres
          '';
        };
      services.hydra = {
        enable = true;
        useSubstitutes = true;
        hydraURL = "https://hydra.example.org";
        notificationSender = "damian.baar@gmail.com";
        buildMachinesFiles = [];
        extraConfig = ''
          store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/${host-name}/secret
          binary_cache_secret_key_file = /etc/nix/${host-name}/secret
          binary_cache_dir = /var/lib/hydra/cache
        '';
      };
      security.acme.certs."${host-name}" = {
        # webroot = "/var/www/challenges";
        email = "foo@example.com";
      };
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
    
        virtualHosts."${host-name}" = {
          forceSSL = true;
          # enableACME = true;
          enableACME = true;
          locations."/" ={
            proxyPass = "http://localhost:3000";
          };
        };
      };
      systemd.services.hydra-manual-setup = {
        description = "Create Admin User for Hydra";
        serviceConfig.Type = "oneshot";
        serviceConfig.RemainAfterExit = true;
        wantedBy = [ "multi-user.target" ];
        requires = [ "hydra-init.service" ];
        after = [ "hydra-init.service" ];
        environment = builtins.removeAttrs (config.systemd.services.hydra-init.environment) ["PATH"];
        script = ''
          if [ ! -e ~hydra/.setup-is-complete ]; then
            # create signing keys
            /run/current-system/sw/bin/install -d -m 551 /etc/nix/${host-name}
            /run/current-system/sw/bin/nix-store --generate-binary-cache-key ${host-name} /etc/nix/${host-name}/secret /etc/nix/${host-name}/public

            /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/${host-name}
            /run/current-system/sw/bin/chmod 440 /etc/nix/${host-name}/secret
            /run/current-system/sw/bin/chmod 444 /etc/nix/${host-name}/public

            # create cache
            /run/current-system/sw/bin/install -d -m 755 /var/lib/hydra/cache
            /run/current-system/sw/bin/chown -R hydra-queue-runner:hydra /var/lib/hydra/cache

            # done
            touch ~hydra/.setup-is-complete
          fi
        '';
      };
       security.acme.preliminarySelfsigned = true;
  # systemd.services.nginx = {
  #   after = [ "acme-selfsigned-certificates.target" ];
  #   wants = [ "acme-selfsigned-certificates.target" "acme-certificates.target" ];
  # };
      nix.gc = {
        automatic = true;
        dates = "15 3 * * *"; # [1]
      };

      nix.autoOptimiseStore = true;
      nix.trustedUsers = ["hydra" "hydra-evaluator" "hydra-queue-runner"];
      networking.firewall.allowedTCPPorts = [ config.services.hydra.port 80 22 ];
      nix.buildMachines = [
        {
          hostName = "localhost";
          systems = [ "x86_64-linux" "i686-linux" ];
          maxJobs = 6;
          # for building VirtualBox VMs as build artifacts, you might need other 
          # features depending on what you are doing
          supportedFeatures = [ ];
        }
      ];
    };
}
