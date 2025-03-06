FROM alpine:3.21 AS build

RUN apk add --no-cache tzdata

# remove busybox and apk related data and configs
RUN rm -rv \
	/etc/busybox* \
	/etc/modprobe.d/* \
	/etc/udhcpc \
	/lib/apk \
	/usr/share/apk \
	/usr/share/udhcpc

# remove binaries and symlinks to binaries
RUN scanelf --nobanner --mount --format %F --recursive / | xargs rm -vf \
	/*bin/* \
	/lib/libc* \
	/usr/*bin/* \
	/usr/lib/lib*

FROM scratch
COPY --from=build / /

