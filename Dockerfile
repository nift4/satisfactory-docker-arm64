# Use the official Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    cmake \
    ninja-build \
    pkg-config \
    ccache \
    clang \
    llvm \
    lld \
    binfmt-support \
    libsdl2-dev \
    libepoxy-dev \
    libssl-dev \
    python-setuptools \
    g++-x86-64-linux-gnu \
    nasm \
    python3-clang \
    libstdc++-10-dev-i386-cross \
    libstdc++-10-dev-amd64-cross \
    libstdc++-10-dev-arm64-cross \
    squashfs-tools \
    squashfuse \
    libc-bin \
    expect \
    curl \
    sudo \
    fuse \
    systemd

# Create a new user and set their home directory
RUN useradd -m -s /bin/bash fex

RUN usermod -aG sudo fex

RUN echo "fex ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/fex

USER fex

WORKDIR /home/fex

# Clone the FEX repository and build it
RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git && \
    cd FEX && \
    mkdir Build && \
    cd Build && \
    CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja .. && \
    ninja

WORKDIR /home/fex/FEX/Build

RUN sudo ninja install

RUN sudo useradd -m -s /bin/bash steam

RUN sudo apt install wget

USER root

RUN echo 'root:steamcmd' | chpasswd

USER steam

RUN mkdir -p /home/steam/.fex-emu/RootFS/ /home/steam/Steam

WORKDIR /home/steam/.fex-emu/RootFS/

# Set up rootfs

RUN wget -O Ubuntu_22_04.tar.gz https://www.dropbox.com/scl/fi/16mhn3jrwvzapdw50gt20/Ubuntu_22_04.tar.gz?rlkey=4m256iahwtcijkpzcv8abn7nf

RUN tar xzf Ubuntu_22_04.tar.gz

RUN rm ./Ubuntu_22_04.tar.gz

WORKDIR /home/steam/.fex-emu

RUN echo '{"Config":{"RootFS":"Ubuntu_22_04"}}' > ./Config.json
RUN echo 'env CPU_MHZ=3000 FEXBash /home/steam/start2.sh' > /home/steam/start.sh
RUN echo 'cd /home/steam/Steam; ./steamcmd.sh +@sSteamCmdForcePlatformBitness 64 +force_install_dir ~/SatisfactoryDedicatedServer +login anonymous +app_update 1690800 -beta experimental validate +quit; chmod -R 777 ~/SatisfactoryDedicatedServer; cd ~/SatisfactoryDedicatedServer/; ./FactoryServer.sh -log -Port 17777' > /home/steam/start2.sh

WORKDIR /home/steam/Steam

# Download and run SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

RUN chmod +x /home/steam/start.sh /home/steam/start2.sh
ENTRYPOINT /home/steam/start.sh

# Step 1: docker build --ulimit nofile=1048576:1048576 --tag 'satis' .
# Step 2: docker run --name debian-satisfactory-server -p 7777:7777 -p 17777:17777 -p 15000:15000 -p 15777:15777 satis
