# https://github.com/guibou/nixGL
nix-channel --add https://github.com/guibou/nixGL/archive/master.tar.gz nixgl
nix-channel --update
nix-env -iA nixgl.nixGLDefault   # or replace `nixGLDefault` with your desired wrapper
