ARG RUBY_VERSION="3.4.8"
ARG IMAGE_NAME="ruby:${RUBY_VERSION}-slim-trixie"
# hadolint ignore=DL3006
FROM ${IMAGE_NAME}

LABEL maintainer="Bas Hintemann <bas@feedbackfruits.com>"
LABEL org.opencontainers.image.source=https://github.com/feedbackfruits/ruby-jemalloc-docker

ARG RUBY_VERSION
ARG RUBY_CHECKSUM="53c4ddad41fbb6189f1f5ee0db57a51d54bd1f87f8755b3d68604156a35b045b"
ARG ADDITIONAL_FLAGS

ENV DEBIAN_FRONTEND="noninteractive" \
	RUBY_VERSION="${RUBY_VERSION}"
WORKDIR /tmp/build

SHELL ["/bin/bash", "-o","pipefail", "-c"]
# hadolint ignore=DL3008,DL3003,SC1091
RUN apt-get update && \
	apt-get install -y --no-install-recommends curl \
	ca-certificates \
	python3 \
	apt-utils \
	build-essential \
	bison \
	libyaml-dev \
	libgdbm-dev \
	libreadline-dev \
	libjemalloc-dev \
	libncurses5-dev \
	libffi-dev \
	zlib1g-dev \
	libssl-dev && \
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain=1.84.0 && \
	source "${HOME}/.cargo/env" && \
	curl -L -o "ruby-${RUBY_VERSION}.tar.gz" "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz" && \
	echo "${RUBY_CHECKSUM}  ruby-${RUBY_VERSION}.tar.gz" | sha256sum --strict -c - && \
	tar xf "ruby-${RUBY_VERSION}.tar.gz" && \
	cd "ruby-${RUBY_VERSION}" && \
	./configure --prefix=/opt/ruby \
	--with-jemalloc \
	--enable-shared \
	--disable-install-doc \
	"${ADDITIONAL_FLAGS}" && \
	make -j"$(nproc)" > /dev/null && \
	make install && \
	rustup self uninstall -y && \
	rm -rf /tmp/build && \
	apt-get clean

ENV LD_PRELOAD="libjemalloc.so.2"
ENV MALLOC_CONF="dirty_decay_ms:0,muzzy_decay_ms:0,narenas:2,background_thread:true,thp:never"

WORKDIR /
