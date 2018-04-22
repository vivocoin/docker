FROM ubuntu:xenial
WORKDIR /root/build
RUN echo "deb http://ppa.launchpad.net/bitcoin/bitcoin/ubuntu xenial main" > /etc/apt/sources.list.d/bitcoin.list && \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8842CE5E && \
	apt-get update && \
	apt-get install -y \
		git \
		libboost-all-dev \
		libdb4.8++-dev \
		libzmq5-dev \
		libminiupnpc-dev \
		libssl-dev \
		libevent-dev \
		protobuf-compiler \
		qt5-default \
		qttools5-dev-tools \
		autoconf \
		automake \
		pkg-config \
		build-essential \
		libtool && \
	git clone https://github.com/vivocoin/vivo && \
	cd vivo && \
	./autogen.sh && \
	./configure \
		--disable-static \
		--disable-shared \
		--disable-tests \
		--disable-bench \
		--without-libs \
		--with-gui=qt5 \
		--with-daemon \
		--prefix=/root/build/vivo/install && \
	make -j $(nproc) && \
	make install && \
	strip \
		--strip-unneeded \
		-R .comment \
		-R .GCC.command.line \
		-R .note.gnu.gold-version \
		/root/build/vivo/install/bin/*

VOLUME /data
ENTRYPOINT cp /root/build/vivo/install/bin/* /data/
