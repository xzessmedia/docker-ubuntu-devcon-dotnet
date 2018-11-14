FROM xzesstence/docker-ubuntu
MAINTAINER "Tim Koepsel"

LABEL dotnet-version="2.1.4"

ENV TZ 'Europe/Brussels'

# https://bugs.debian.org/830696 (apt uses gpgv by default in newer releases, rather than gpg)
RUN set -ex; \
        apt-get update; \
        if ! which gpg; then \
                apt-get install -y --no-install-recommends gnupg; \
        fi; \
# Ubuntu includes "gnupg" (not "gnupg2", but still 2.x), but not dirmngr, and gnupg 2.x requires dirmngr
# so, if we're not running gnupg 1.x, explicitly install dirmngr too
        if ! gpg --version | grep -q '^gpg (GnuPG) 1\.'; then \
                 apt-get install -y --no-install-recommends dirmngr; \
        fi; \
        rm -rf /var/lib/apt/lists/*


RUN apt-key adv --keyserver packages.microsoft.com --recv-keys EB3E94ADBE1229CF && apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893

RUN export DEBIAN_FRONTEND=noninteractive && DEBIAN_FRONTEND=noninteractive apt-get update \
 && echo $TZ > /etc/timezone \
 && apt-get install -y net-tools \
                       iputils-ping \
                       curl \
                       wget \
                       ca-certificates \
                       unzip \
                       tzdata \
 && curl https://packages.microsoft.com/keys/microsoft.asc | /usr/bin/gpg --dearmor > microsoft.gpg \
 && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
 && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-bionic-prod bionic main" > /etc/apt/sources.list.d/dotnetdev.list' \
 && apt-get update

RUN apt-get install -y dotnet-sdk-2.1.105  \
                       aspnetcore-store-2.0.6

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
 && dpkg-reconfigure -f noninteractive tzdata \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*


RUN useradd -d /home/xdev -ms /bin/bash -g root -G sudo xdev
RUN echo 'xdev:123456' | chpasswd
USER xdev
WORKDIR /home/xdev

RUN echo 'alias xrefresh="source ~/.bash_aliases"' >> ~/.bash_aliases
RUN echo 'alias xwww="cd /var/www/html"' >> ~/.bash_aliases
RUN echo 'alias xalias="sudo vi ~/.bash_aliases"' >> ~/.bash_aliases
RUN echo 'alias xspace="df -h"' >> ~/.bash_aliases
RUN /bin/bash -c "source ~/.bash_aliases"


CMD sudo /etc/init.d/ssh start

ENTRYPOINT ["tail", "-f", "/dev/null"]
CMD ["bash"]