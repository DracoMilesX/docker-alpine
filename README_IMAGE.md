![docker-alpine](https://pkgs.alpinelinux.org/assets/alpinelinux-logo.svg)

## github
[https://github.com/xataz/docker-alpine](https://github.com/xataz/docker-alpine)

## Tag available
* 3.3
* 3.4
* 3.5, latest
* edge

## Description
What is [Alpine Linux](https://alpinelinux.org/)

Small. Simple. Secure.
Alpine Linux is a security-oriented, lightweight Linux distribution based on musl libc and busybox.

### About
Alpine Linux is an independent, non-commercial, general purpose Linux distribution designed for power users who appreciate security, simplicity and resource efficiency.

### Small
Alpine Linux is built around musl libc and busybox. This makes it smaller and more resource efficient than traditional GNU/Linux distributions. A container requires no more than 8 MB and a minimal installation to disk requires around 130 MB of storage. Not only do you get a fully-fledged Linux environment but a large selection of packages from the repository.

Binary packages are thinned out and split, giving you even more control over what you install, which in turn keeps your environment as small and efficient as possible.

### Simple
Alpine Linux is a very simple distribution that will try to stay out of your way. It uses its own package manager called apk, the OpenRC init system, script driven set-ups and that’s it! This provides you with a simple, crystal-clear Linux environment without all the noise. You can then add on top of that just the packages you need for your project, so whether it’s building a home PVR, or an iSCSI storage controller, a wafer-thin mail server container, or a rock-solid embedded switch, nothing else will get in the way.

### Secure
Alpine Linux was designed with security in mind. The kernel is patched with an unofficial port of grsecurity/PaX, and all userland binaries are compiled as Position Independent Executables (PIE) with stack smashing protection. These proactive security features prevent exploitation of entire classes of zero-day and other vulnerabilities.

## Why recreate alpine image ?
Official image is not updated regularly. This image is updated once a day only if necessary.

## How to use this image
Use like you would any other base image :
```shell
FROM xataz/alpine:3.4
RUN apk add --no-cache nginx

ENTRYPOINT ["nginx"]
```

## Contributing
Any contributions, are very welcome !