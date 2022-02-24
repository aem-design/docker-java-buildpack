FROM    aemdesign/oracle-jdk:jdk8-ubuntu

LABEL   os="ubuntu" \
        container.description="centos with java build pack" \
        version="1.0.0" \
        imagename="java-buildpack" \
        maintainer="devops@aem.design" \
        test.command="source ~/.nvm/nvm.sh; node --version" \
        test.command.verify="v17.6.0"

#https://chromedriver.storage.googleapis.com/
ARG CHROME_DRIVER_VERSION="99.0.4844.35"
ARG CHROME_DRIVER_FILE="chromedriver_linux64.zip"
ARG CHROME_DRIVER_URL="https://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/${CHROME_DRIVER_FILE}"
ARG CHROME_FILE="google-chrome-stable_current_x86_64.rpm"
ARG CHROME_URL="https://dl.google.com/linux/direct/${CHROME_FILE}"
ARG NODE_VERSION="17.6.0"
ARG NVM_URL="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"
ARG MAVEN_VERSION="3.6.3"
ARG MAVEN_FILE="apache-maven-${MAVEN_VERSION}-bin.zip"
ARG MAVEN_URL="http://mirrors.sonic.net/apache/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_FILE}"
ARG RVM_VERSION=stable
ARG RVM_USER=rvm
ARG RVM_INSTALL_VERSION="3.1.1"
ARG GROOVY_VERSION="3.0.7"

ENV RVM_USER=${RVM_USER}
ENV RVM_VERSION=${RVM_VERSION}
ENV HOME="/build"
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN mkdir -p $HOME

WORKDIR $HOME

ENV REQUIRED_PACKAGES \
    build-essential \
    curl \
    tar \
    zip \
    unzip \
    ruby \
    rsync \
    python3-dev \
    python3-setuptools \
    python3-pip \
    autoconf \
    make \
    gcc \
    openssh-server \
    vim \
    git \
    git-lfs \
    wget \
    bzip2 \
    ca-certificates \
    chrpath \
    fontconfig \
    libfreetype-dev \
    libfontconfig \
    libstdc++-10-dev \
    imagemagick \
    libcurl4-openssl-dev \
    libffi-dev \
    libltdl-dev \
    libpng-dev \
    pngquant \
    sudo \
    gnupg2 \
    libwebp-dev \
    yarn \
    ansible \
    tzdata \
    jq

RUN \
    echo "==> Make dirs..." && \
    mkdir -p /apps/

RUN \
    echo "==> Setup packages..." && \
    apt-get update -y

RUN \
    echo "==> Install packages..." && \
    apt-get install -y software-properties-common && \
    apt-get install -y ${REQUIRED_PACKAGES} && \
    ln -s /usr/bin/python3 /usr/bin/python

RUN \
    echo "==> Install Docker Client" && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get install -y docker-ce-cli && \
    pip3 install --upgrade pip && \
    pip install docker-compose

RUN \
    echo "==> Install SDKMAN..." && \
    export SDKMAN_DIR=$HOME

RUN curl -s https://get.sdkman.io | bash

RUN \
    . "$HOME/.sdkman/bin/sdkman-init.sh" && \
    sdk version && \
    sdk install groovy $GROOVY_VERSION

RUN \
    echo "==> Install nvm..." && \
    export NVM_DIR="/build/.nvm" && \
    mkdir -p ${NVM_DIR} && touch .bashrc && \
    curl -o- ${NVM_URL} | bash && . $HOME/.bashrc && \
    nvm install $NODE_VERSION && nvm use --delete-prefix ${NODE_VERSION} && \
    echo "==> Install npm packages..." && \
    npm install -g npm

RUN \
    echo "==> Install chrome..." && \
    wget ${CHROME_DRIVER_URL} && unzip ${CHROME_DRIVER_FILE} && mv chromedriver /usr/bin && rm -f ${CHROME_DRIVER_FILE} && \
    wget ${CHROME_URL} && yum install -y Xvfb ${CHROME_FILE} && rm -f ${CHROME_FILE}

RUN \
    echo "==> Install maven..." && \
    wget ${MAVEN_URL} && unzip ${MAVEN_FILE} && mv apache-maven-${MAVEN_VERSION} /apps/maven && rm -f ${MAVEN_FILE} && \
    echo "export PATH=/apps/maven/bin:${PATH}">/etc/profile.d/maven.sh && \
    echo "export PATH=/apps/maven/bin:${PATH}">>$HOME/.bashrc && \
    echo "export PATH=/apps/maven/bin:${PATH}">>/etc/profile.d/sh.local && \
    ln -s /apps/maven/bin/mvn /usr/bin/mvn

RUN \
    echo "==> Disable requiretty..." && \
    sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers && \
    echo "ALL  ALL=(ALL) NOPASSWD: ALL">>/etc/sudoers

RUN \
    echo "==> Set Oracle JDK as Alternative..." && \
    rm -rf /var/lib/alternatives/java && \
    rm -rf /var/lib/alternatives/jar && \
    rm -rf /var/lib/alternatives/javac && \
    alternatives --install "/usr/bin/java" "java" "/usr/java/default/bin/java" 2 && \
    alternatives --install "/usr/bin/jar" "jar" "/usr/java/default/bin/jar" 2 && \
    alternatives --install "/usr/bin/javac" "javac" "/usr/java/default/bin/javac" 2 && \
    alternatives --set java "/usr/java/default/bin/java" && \
    alternatives --set jar "/usr/java/default/bin/jar" && \
    alternatives --set javac "/usr/java/default/bin/javac"

RUN \
    echo "==> Install RVM..." && \
    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - && \
    curl -L get.rvm.io | bash -s $RVM_VERSION && \
    echo "==> Source RVM..." && \
    echo "export PATH=\$PATH:/usr/local/rvm/bin">>/build/.bashrc && \
    export PATH=$PATH:/usr/local/rvm/bin && \
    . /usr/local/rvm/scripts/rvm && \
    echo "==> Reload RVM..." && \
    touch /etc/rvmrc && \
    echo "rvm_silence_path_mismatch_check_flag=1" >> /etc/rvmrc && \
    touch /usr/local/rvm/gemsets/global.gems && \
    echo "bundler" >> /usr/local/rvm/gemsets/global.gems && \
    rvm reload && \
    rvm requirements run && \
    rvm install ${RVM_INSTALL_VERSION}

RUN \
    echo "==> Update scripts" && \
    touch $HOME/.bash_profile && echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" >> $HOME/.bash_profile

RUN useradd -m --no-log-init -r -g rvm ${RVM_USER}
