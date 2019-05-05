{
  my-hydra = 
    { config, pkgs, ... }: {
      # nixpkgs.localSystem.system = "x86_64-linux";
      # pkgs.localSystem.system = "x86_64-linux";

      deployment.targetEnv                    = "virtualbox";

        virtualisation.virtualbox.guest.enable = true;
      deployment.virtualbox.memorySize        = 4096;
      deployment.virtualbox.vcpu              = 2;
      deployment.virtualbox.headless          = true;
      services.nixosManual.showManual         = false;
      services.ntp.enable                     = false;
    programs.ssh = {
      knownHosts = [
      { hostNames = [ "github.com" "140.82.118.4" ]; publicKey = ""; }
      ];
      extraConfig = ''
          StrictHostKeyChecking no
        '';
  };
      # services.openssh.allowSFTP              = false;
      # services.openssh.enable = true;
      # services.openssh.passwordAuthentication = false;
      # services.openssh.permitRootLogin="yes";
      users = {
        mutableUsers = false;
        users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
        # users.damianbaar.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
      };
    };
}
