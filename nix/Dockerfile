FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y sudo curl bzip2 locales
RUN locale-gen en_US.UTF-8

RUN mkdir -p /etc/nix /nix
RUN echo "build-users-group =" > /etc/nix/nix.conf

RUN groupadd -g 1000 appuser
RUN useradd -g appuser -u 1000 appuser
RUN mkdir -p /home/appuser

RUN echo "appuser ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/appuser
RUN chmod 0440 /etc/sudoers.d/appuser

RUN chown -R appuser:appuser /nix
RUN chown -R appuser:appuser /home/appuser

USER appuser
ENV USER=appuser
RUN curl https://nixos.org/nix/install | sh

RUN echo '. $HOME/.nix-profile/etc/profile.d/nix.sh' >> $HOME/.bashrc
RUN mkdir -p $HOME/.nixpkgs
# https://github.com/moby/moby/issues/6119
COPY --chown=appuser:appuser *.nix /home/appuser/.nixpkgs/
