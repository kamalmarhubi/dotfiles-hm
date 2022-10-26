# Remaining:
# - start using it at work
{
  description = "Kamal pretends to use nix?";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: let
    maker = { system, homeDirectory, ... }: let
     pkgs = nixpkgs.legacyPackages.${system};
    in
    home-manager.lib.homeManagerConfiguration {
     inherit pkgs;

     # Specify your home configuration modules here, for example,
     # the path to your home.nix.
     modules = [
       ./dotfiles-nix.nix
       {
         programs = {
           home-manager.enable = true;
           fish.enable = true;
           neovim = {
             enable = true;
             plugins = with pkgs.vimPlugins; [
             ];
           };
         };

         home = {
           username = "kamal";
           inherit homeDirectory;
           stateVersion = "22.11";

           sessionVariables = {
             EDITOR = "nvim";
           };
         };
         # For whatever reason, the installer didn't put this somewhere that
         # fish would see. Since the nix-daemon.fish file guards against
         # double-sourcing, there's no harm including this in all systems.
         xdg.configFile."fish/conf.d/nix.fish".text = ''
           # Nix
           if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
             . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
           end
           # End Nix
         '';
       }
     ];
    };
  in
  {
    homeConfigurations = rec {
      genericLinux = maker {
        system = "x86_64-linux";
        homeDirectory = "/home/kamal";
      };
      genericMacos = maker {
        system = "aarch64-darwin";
        homeDirectory = "/Users/kamal";
      };
      "kamal@kx7" = genericLinux;
      "kamal@kmbpwave.local" = genericMacos;
    };
  };
}
