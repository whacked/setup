# syntax=docker/dockerfile:1

FROM ubuntu:latest

ARG GROUP_ID=1000
ARG USER_ID=1000
ARG OPERATING_GROUP=fleet
ARG OPERATING_USER=captain


RUN apt-get update
RUN apt-get install -y sudo curl bzip2 locales xz-utils git && \
        locale-gen en_US.UTF-8

RUN mkdir -p /etc/nix /nix; echo "build-users-group =" > /etc/nix/nix.conf

RUN groupadd -g $GROUP_ID $OPERATING_GROUP && \
        useradd -g $OPERATING_GROUP -u $USER_ID $OPERATING_USER && \
        mkdir -p /home/$OPERATING_USER

RUN echo "$OPERATING_USER ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$OPERATING_USER && \
        chmod 0440 /etc/sudoers.d/$OPERATING_USER && \
        chown -R $OPERATING_USER:$OPERATING_GROUP /nix /home/$OPERATING_USER

# generates /etc/machine-id, should be unique per machine;
# electron needs it to start
# RUN systemd-machine-id-setup
# alternatively:
# RUN cat /dev/urandom | head -c 99 | md5sum - | head -c 32 > /etc/machine-id

USER $OPERATING_USER
ENV USER=$OPERATING_USER
RUN curl -L https://nixos.org/nix/install | sh && echo '. $HOME/.nix-profile/etc/profile.d/nix.sh' | tee -a $HOME/.bashrc | tee -a $HOME/.bash_profile
# </ubuntu>

RUN git clone https://github.com/whacked/setup /home/$OPERATING_USER/setup
WORKDIR /home/$OPERATING_USER
