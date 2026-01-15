{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Build tools
    gnumake
    gcc
    
    # R with packages
    (rWrapper.override {
      packages = with rPackages; [
        tidyverse
        ggplot2
        scales
        lubridate
        broom
        fmsb
      ];
    })
  ];

  shellHook = ''
    echo "=========================================="
    echo "  NixOS R Environment for Data Science"
    echo "  Counties: Cheshire and Cumberland"
    echo "=========================================="
    echo ""
    echo "R and all packages are ready!"
    echo ""
    echo "To run the analysis:"
    echo "  Rscript run_analysis.R"
    echo ""
    echo "Or open R interactively:"
    echo "  R"
    echo "  source('run_analysis.R')"
    echo "=========================================="
  '';
}
