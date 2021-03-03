# other
with import <nixpkgs> {};
[
    # containerization
    singularity
    # daemonless docker
    buildah
    conmon
    podman
    runc
    shadow
    skopeo
    slirp4netns
]

# NOTE:
#  - for podman to work, you will have to
#    sudo chmod 4755 $(which newuidmap)
#    sudo chmod 4755 $(which newgidmap)
