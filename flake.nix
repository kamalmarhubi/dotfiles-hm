# TODOs
# - neovim
#   - add in plugins I know I like
#   - try out that import.nvim thing?
#   - don't bother with lazy loading or packadd
#   - do try to dry
{
  description = "Kamal pretends to use nix?";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    neovim-unpackaged-plugins.url = "path:./flakes/neovim-unpackaged-plugins";
  };

  outputs = {
    nixpkgs,
    home-manager,
    flake-utils,
    neovim-unpackaged-plugins,
    ...
  }: let
    homeDirectoryFor = system: username:
      if builtins.match ".*darwin" system != null
      then "/Users/${username}"
      else "/home/${username}";
    homeFor = {
      username ? "kamal",
      system,
      homeDirectory ? homeDirectoryFor system username,
      ...
    }: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./dotfiles-nix.nix
          neovim-unpackaged-plugins.module
          ({config, ...}: {
            programs = {
              home-manager.enable = true;
              fish.enable = true;
              neovim = {
                enable = true;
                plugins = with pkgs.vimPlugins; [
                  leap-nvim
                ];
              };
            };

            home = {
              inherit username homeDirectory;
              stateVersion = "22.11";

              sessionVariables = {
                EDITOR = "nvim";
              };

              packages = with pkgs; [
                atool
                entr
                fd
                ripgrep
                pv
                tree
                wget
              ];
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
            xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/.local/share/dotfiles-nix/files/nvim";
          })
        ];
      };
  in
    {
      # For bootstrapping systems that aren't aleady in the homeConfigurations output.
      inherit homeFor;
      homeConfigurations = {
        "kamal@kx7" = homeFor {
          system = "x86_64-linux";
        };
        "kamal@kmbpwave.local" = homeFor {
          system = "aarch64-darwin";
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.alejandra;
    });
}
