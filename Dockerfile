# The FROM instruction initializes a new build stage and sets the Base Image for
# subsequent instructions. As such, a valid Dockerfile must start with a FROM
# instruction. The image can be any valid image – it is especially easy to start
# by pulling an image from the Public Repositories.
FROM ubuntu:14.04

# The ENV instruction sets the environment variable <key> to the value <value>.
# This value will be in the environment of all “descendant” Dockerfile commands
# and can be replaced inline in many as well.
ENV http_proxy ${http_proxy:-}
ENV https_proxy ${https_proxy:-}
ENV no_proxy ${no_proxy:-}
ENV OUT_DIR_COMMON_BASE /temp/out/dist

# this may be problematic on gcloud... but let's keep it for now
ENV USER root

# The RUN instruction will execute any commands in a new layer on top of the
# current image and commit the results. The resulting committed image will be
# used for the next step in the Dockerfile.

# -q, --quiet
# Quiet. Produces output suitable for logging, omitting progress indicators. 
# More q's will produce more quiet up to a maximum of two. You can also use -q=#
# to set the quiet level, overriding the configuration file. Note that quiet
# level 2 implies -y, you should never use -qq without a no-action modifier such
# as -d, --print-uris or -s as APT may decided to do something you did not
# expect.
RUN apt-get -qq update
# -y accepts automatically
RUN apt-get -qqy upgrade

# debconf-set-selections - insert new values into the debconf database
# dpkg-reconfigure sets the /bin/sh back to dash, reconfiguring its -p
# (priority) of questions to only those criticals. I assume this is done so the
# build does not hang on questions
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure -p critical dash

# install all of the tools and libraries that we need.
RUN apt-get update && \
    apt-get install -y bc bison bsdmainutils build-essential curl \
        flex g++-multilib gcc-multilib git gnupg gperf lib32ncurses5-dev \
        lib32readline-gplv2-dev lib32z1-dev libesd0-dev libncurses5-dev \
        libsdl1.2-dev libwxgtk2.8-dev libxml2-utils lzop \
        openjdk-7-jdk \
        pngcrush schedtool xsltproc zip zlib1g-dev

# The ADD instruction copies new files, directories or remote file URLs from
# <src> and adds them to the filesystem of the image at the path <dest>.
ADD https://commondatastorage.googleapis.com/git-repo-downloads/repo \
  /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

# 
RUN apt-get update && apt-get install -y \
 software-properties-common python-software-properties

# We need this because of this
# https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/
# Here is solution
# https://engineeringblog.yelp.com/2016/01/dumb-init-an-init-for-docker.html
RUN curl --create-dirs -sSLo /usr/local/bin/dumb-init \
  https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64
RUN chmod +x /usr/local/bin/dumb-init

# Extras that android-x86.org and android-ia need
RUN apt-get update && apt-get install -y gettext python-libxml2 yasm bc
RUN apt-get update && apt-get install -y squashfs-tools genisoimage dosfstools mtools
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# We don't want compiler cache, probably because it takes too much storage...?
# setting up CCACHE
# RUN echo "export USE_CCACHE=1" >> /etc/profile.d/android
# ENV USE_CCACHE 1
# ENV CCACHE_DIR /ccache

# The COPY instruction copies new files or directories from <src> and adds them
# to the filesystem of the container at the path <dest>.
COPY build.sh /script/build.sh
RUN chmod 755 /script/build.sh

# The WORKDIR instruction sets the working directory for any RUN, CMD,
# ENTRYPOINT, COPY and ADD instructions that follow it in the Dockerfile. If the
# WORKDIR doesn’t exist, it will be created even if it’s not used in any
# subsequent Dockerfile instruction.

# The WORKDIR instruction can be used multiple times in a Dockerfile. If a
# relative path is provided, it will be relative to the path of the previous
# WORKDIR instruction. For example:
WORKDIR /android-repo

CMD ["/usr/local/bin/dumb-init", "--", "/script/build.sh"]
