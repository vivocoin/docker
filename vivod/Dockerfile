FROM alpine:latest as build
WORKDIR /root/build
RUN apk update && \
	apk add git build-base boost-dev autoconf automake libtool libevent-dev zeromq-dev db-dev libressl-dev make && \
	git clone https://github.com/vivocoin/vivo && \
	cd vivo && \
	chmod +x share/genbuild.sh && \
	sh autogen.sh && \
	./configure \
		--disable-static \
		--disable-shared \
		--disable-tests \
		--disable-bench \
		--without-miniupnpc \
		--without-libs \
		--without-utils \
		--with-gui=no \
		--with-daemon \
		--with-incompatible-bdb \
		--prefix=/root/build/vivo/install && \
	make -j 5 && \
	make install && \
	strip --strip-unneeded -R .comment -R .GCC.command.line -R .note.gnu.gold-version /root/build/vivo/install/bin/*

FROM alpine:latest as assemble
RUN apk update && \
	apk --no-cache add libevent zeromq db-c++ libressl && \
	adduser -s /bin/false -D vivo
COPY --from=build \
	/usr/lib/libboost_system.so.1.62.0 \
	/usr/lib/libboost_filesystem.so.1.62.0 \
	/usr/lib/libboost_program_options-mt.so.1.62.0 \
	/usr/lib/libboost_system-mt.so.1.62.0 \
	/usr/lib/libboost_thread-mt.so.1.62.0 \
	/usr/lib/libboost_chrono-mt.so.1.62.0 \
	/usr/lib/
WORKDIR /opt/wallet/vivo
COPY --from=build /root/build/vivo/install/bin/vivod .
COPY init.sh bootstrap.sh ./
RUN chmod 755 init.sh bootstrap.sh

FROM scratch
COPY --from=assemble / /
RUN chown vivo:vivo -R /home/vivo
USER vivo:vivo
EXPOSE 9998 12845
ENV SECRET_OVERRIDE=0 VIVO_RPCUSER=vivo VIVO_RCPPASSWORD=vivo
ENTRYPOINT [ "/opt/wallet/vivo/init.sh", "-printtoconsole" ]
