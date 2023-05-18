{
  description = "meanvoid nix/nixos/darwin  nix flake configuration";

  inputs = {
    ### --- nixpkgs --- ###
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/nur";
    nixpkgs.follows = "unstable"; # desc: set nixos-unstable as default nixpkgs
    ### --- nixpkgs --- ###

    ### --- systems --- ###
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "unstable";
    };
    wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "unstable";
    };
    ### --- systems --- ###

    ### --- modules --- ###
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "unstable";
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "unstable";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "unstable";
    };
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "unstable";
    };

    nixpkgs-fmt.url = "github:nix-community/nixpkgs-fmt";
    ### --- modules --- ###

    ### --- overlays --- ###
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      flake = false;
    };
    doom-emacs = {
      url = "github:nix-community/nix-doom-emacs";
      inputs.nixpkgs.follows = "unstable";
      inputs.emacs-overlay.follows = "emacs-overlay";
    };
    hyprland = {
      url = "github:vaxerski/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comma = {
      url = "github:nix-community/comma";
      flake = false;
    };
    spicetify-nix.url = "github:the-argus/spicetify-nix";
    ### --- overlays --- ###
  };

  outputs = {
    self,
    nixpkgs,
    nur,
    darwin,
    home-manager,
    agenix,
    aagl,
    doom-emacs,
    spicetify-nix,
    ...
  } @ inputs: let
    users = {
      marie = "ashuramaru";
      alex = "meanrin";
      twi = "twithefurry";
      kelly = "kellyreanimausu";
      morgana = "theultydespair";
    };
    path = "/etc/nixos";
  in {
    nixosConfigurations = (
      import ./hosts/linux {
        inherit (nixpkgs) lib;
        inherit inputs self nixpkgs nur agenix aagl users path home-manager spicetify-nix;
      }
    );
    darwinConfigurations = (
      import ./hosts/darwin {
        inherit (nixpkgs) lib;
        inherit inputs self darwin nixpkgs home-manager users;
      }
    );
    formatter = {
      x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;
      aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
      i686-linux = nixpkgs.legacyPackages.i686-linux.alejandra;
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.alejandra;
    };
  };
}
