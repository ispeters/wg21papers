{
  description = "Build environment for WG21 papers rendered with mpark/wg21";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  # The reference implementation P4223's examples are compiled against (see
  # `make check`). Pinned to a commit so the check doesn't change under the
  # paper; it's a plain source tree, used only for its headers.
  inputs.stdexec = {
    url = "github:ispeters/stdexec/9a85c0ac643fb7e52bbaf5d4e4788192f0e81bce";
    flake = false;
  };

  outputs =
    { nixpkgs, stdexec, ... }:
    let
      inherit (nixpkgs) lib;

      # mpark/wg21 pins an exact pandoc release and would download it itself.
      # Use the same upstream binaries (rather than nixpkgs' pandoc) so rendered
      # output matches what its Makefile expects. Must agree with PANDOC_VER in
      # the mpark.wg21 submodule; wg21-link-deps checks this.
      pandocVersion = "3.9.0.2";
      pandocReleases = {
        aarch64-darwin = {
          file = "pandoc-${pandocVersion}-arm64-macOS.zip";
          root = "pandoc-${pandocVersion}-arm64";
          hash = "sha256-bp7KhEB2vLtZm77ru6eKcPk7Uwd4K4XCwnKHKBLIiHU=";
        };
        x86_64-linux = {
          file = "pandoc-${pandocVersion}-linux-amd64.tar.gz";
          root = "pandoc-${pandocVersion}";
          hash = "sha256-ppq/q6vailaWmiVLCflVOnvond7ADU4P6f1YXXGmdQg=";
        };
      };

      forAllSystems = lib.genAttrs (builtins.attrNames pandocReleases);
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          release = pandocReleases.${system};

          pandoc = pkgs.stdenvNoCC.mkDerivation {
            pname = "pandoc-bin";
            version = pandocVersion;
            src = pkgs.fetchurl {
              url = "https://github.com/jgm/pandoc/releases/download/${pandocVersion}/${release.file}";
              inherit (release) hash;
            };
            nativeBuildInputs = [ pkgs.unzip ];
            sourceRoot = release.root;
            dontConfigure = true;
            dontBuild = true;
            # Upstream's prebuilt (and, on macOS, signed) binary; leave it as is.
            dontFixup = true;
            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp -R bin share $out/
              runHook postInstall
            '';
          };

          # Mirrors mpark/wg21's deps/requirements.txt (which pins panflute
          # 2.3.1, matching nixpkgs).
          python = pkgs.python3.withPackages (
            ps: with ps; [
              panflute
              beautifulsoup4
              lxml
              requests
              pyyaml
            ]
          );

          # mpark/wg21's Makefile `override`s PANDOC_DIR and PYTHON_DIR (so they
          # can't be set on the command line) and lists them as prerequisites,
          # installing pandoc and a pip venv into its deps/ directory when they
          # are missing. Populate those directories with this shell's tools
          # instead so its installers never run. Python gets exec wrappers
          # rather than symlinks so the interpreter always starts from its own
          # store path. mpark/wg21 gitignores both directories, and `make clean`
          # deletes them: re-run afterwards.
          #
          # With --if-needed it does nothing when the links already point at
          # this shell's tools. That matters because mpark/wg21's bibliography
          # (csl.json) depends on deps/python, so needlessly recreating the
          # links would re-download the references on the next build.
          linkDeps = pkgs.writeShellApplication {
            name = "wg21-link-deps";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.gnused
            ];
            text = ''
              if_needed=0
              if [[ "''${1:-}" == --if-needed ]]; then
                if_needed=1
                shift
              fi
              root="''${1:-$(git rev-parse --show-toplevel)/mpark.wg21}"
              deps="$root/deps"
              if [[ ! -f "$deps/install-pandoc.sh" ]]; then
                echo "error: $root doesn't look like mpark/wg21 (run 'git submodule update --init mpark.wg21', or pass its path)" >&2
                exit 1
              fi
              ver=$(cat "$root/Makefile" "$root/base.mk" 2>/dev/null | sed -n 's/^override PANDOC_VER := //p' | head -n1 || true)
              if [[ "$ver" != "${pandocVersion}" ]]; then
                echo "error: mpark/wg21 at $root expects pandoc '$ver'; this flake provides ${pandocVersion}" >&2
                exit 1
              fi
              want_pandoc="${pandoc}/bin/pandoc"
              want_python="${python}/bin/python3"
              if ((if_needed)) &&
                [[ "$(readlink "$deps/pandoc/$ver/pandoc" || true)" == "$want_pandoc" ]] &&
                grep -qsF "$want_python" "$deps/python/bin/python3"; then
                exit 0
              fi
              rm -rf "$deps/pandoc" "$deps/python"
              mkdir -p "$deps/pandoc/$ver" "$deps/python/bin"
              ln -s "$want_pandoc" "$deps/pandoc/$ver/pandoc"
              for name in python3 python; do
                printf '#!/bin/sh\nexec %s "$@"\n' "$want_python" > "$deps/python/bin/$name"
                chmod +x "$deps/python/bin/$name"
              done
              echo "wg21-link-deps: using Nix pandoc ${pandocVersion} and Python in $deps"
            '';
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pandoc
              python
              linkDeps
              pkgs.gnumake
              # For `make check`, which compiles papers' examples.
              pkgs.clang
            ];
            STDEXEC_INCLUDE = "${stdexec}/include";
          };
        }
      );
    };
}
