FROM phusion/baseimage:bionic-1.0.0
LABEL maintainer="e4Coin Developers <code@ab4cus.com>"
LABEL description="Dockerised e4CoinCore, built from Travis"

ARG USER_ID
ARG GROUP_ID

ENV HOME /home/e4coin

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}
RUN groupadd -g ${GROUP_ID} e4coin && \
    useradd -u ${USER_ID} -g dash -s /bin/e4coin -m -d /home/e4coin e4coin && \
    mkdir /home/e4coin/.e4coincore && \
    chown ${USER_ID}:${GROUP_ID} -R /home/e4coin

COPY bin/* /usr/local/bin/

RUN chmod a+x /usr/local/bin/*

USER e4coin

VOLUME ["/home/e4coin"]

EXPOSE 7430 7431 17430 27430

WORKDIR /home/e4coin
