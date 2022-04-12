{
  description = "My Android app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs }: {
    overlay =
      (final: prev: {
        inherit (self.packages.${final.system}) android-sdk;
      });
  } // flake-utils.lib.eachSystem
    (with flake-utils.lib.system; [
      x86_64-linux
    ])
    (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlay
          ];
        };

        packageName = "android";

      in
      {

        # nix flake show github:tadfisher/android-nixpkgs
        packages = {
          android-sdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
            cmdline-tools-latest
            build-tools-29-0-3
            platform-tools
            platforms-android-29
            # ndk-21-1-6352462
            ndk-21-4-7075529
            ndk-bundle
            patcher-v4
          ]);
        };

        devShells.dev = pkgs.mkShell {
          packages = with pkgs; [
            rnix-lsp
            zls

            android-sdk
            zig
            jdk11
          ];

          shellHook = ''
            [ $STARSHIP_SHELL ] && exec $STARSHIP_SHELL
          '';

          CURRENT_PROJECT = packageName;
        };

        devShell = self.devShells.${system}.dev;
      });
}
