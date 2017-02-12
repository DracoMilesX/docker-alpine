#!/bin/bash

## VARIABLES ##
SCRIPT_PATH=$(dirname $(realpath $0))
MIRROR="http://dl-cdn.alpinelinux.org/alpine"
IMAGE_NAME="xataz/alpine"
ALPINE_VER="3.5"
UPDATE="false"
PUSH="false"
FORCE="false"
BUILD="false"
LATEST="3.5"

f_usage() {
    echo "=USAGE= ./gen_rootfs.sh"
    echo "          -v <VERSION_ALPINE> choose version of alpine (default : 3.5)"
    echo "          -e <DOCKER_ENV> Add custom environment variable separate by space (default : none)"
    echo "          -i <LIST_INSTALL> Add custom package separate by space (default : none)"
    echo "          -m <MIRROR> Choose alpine mirror (default : http://dl-cdn.alpinelinux.org/alpine)"
    echo "          -t <IMAGE_NAME> Choose image for check update (default : xataz/alpine)"
    echo "          -b <BUILD_NAME> Build image name (default : xataz/alpine)"
    echo "          -p Push image on docker hub"
    echo "          -f Force generate new rootfs"
    echo "          -h show this message"
    echo "Example : ./gen_rootfs -v 3.4 -e http_proxy=http://proxy.local:8080 -i 'wget curl git'"
}

f_log() {
    echo "=$1= $(date +%d/%m/%Y-%H:%M:%S) $2"
}

f_check_maj() {
    f_log INF "Download ${IMAGE_NAME}:${ALPINE_VER}"
    docker pull ${IMAGE_NAME}:${ALPINE_VER} > /dev/null 2>&1
    f_log INF "Check if ${IMAGE_NAME}:${ALPINE_VER} is up to date"
    CHECK_MAJ=$(docker run -ti --rm ${DOCKER_ENV} ${IMAGE_NAME}:${ALPINE_VER} apk version -U | grep -v -e ^fetch -e ^Installed | wc -l)
    if [ ${CHECK_MAJ} -gt 0 ]; then
        UPDATE="true"
        f_log INF "${IMAGE_NAME}:${ALPINE_VER} is not up to date"
    else
        UPDATE="false"
        f_log INF "${IMAGE_NAME}:${ALPINE_VER} is up to date"
    fi
}

f_gen_repos() {
    if [ "${ALPINE_VER}" == "edge" ]; then
        REPOS_URL="${MIRROR}/edge"
        REPOS="main testing community"
    else
        REPOS_URL="${MIRROR}/v${ALPINE_VER}"
        case ${ALPINE_VER} in
            "2.7")
                REPOS="main backports"
            ;;
            "3.0")
                REPOS="main testing"
            ;;
            "3.1")
                REPOS="main"
            ;;
            "3.2")
                REPOS="main"
            ;;
            "3.3")
                REPOS="main community"
            ;;
            "3.4")
                REPOS="main community"
            ;;
            "3.5")
                REPOS="main community"
            ;;
        esac
    fi

    for i in ${REPOS}; do
        REPOSITORIES=${REPOSITORIES}"${REPOS_URL}/${i}\n"
    done
}

f_gen_rootfs() {
    mkdir -p ${SCRIPT_PATH}/${ALPINE_VER}
    docker run -ti --rm ${DOCKER_ENV} -v ${SCRIPT_PATH}/${ALPINE_VER}:/mnt ${IMAGE_NAME}:3.4 sh -c "apk -X ${REPOS_URL}/main -U --allow-untrusted --root /mnt/rootfs --initdb add alpine-base ${PACKAGES} \
                                                            && echo -e '${REPOSITORIES}' > /mnt/rootfs/etc/apk/repositories \
                                                            && rm -rf /mnt/rootfs/var/cache/apk/* /mnt/rootfs/lib/rc /mnt/rootfs/lib/libalpine.sh \
                                                                                /mnt/rootfs/sbin/setup-* /mnt/rootfs/sbin/openrc* /mnt/rootfs/sbin/rc* \
                                                                                /mnt/rootfs/sbin/supervise-daemon /mnt/rootfs/sbin/update-* /mnt/rootfs/sbin/start-stop-daemon \
                                                                                /mnt/rootfs/sbin/service /mnt/rootfs/sbin/runscript /mnt/rootfs/sbin/lbu* \
                                                                                /mnt/rootfs/etc/acpi /mnt/rootfs/etc/rc.conf /mnt/rootfs/etc/runlevels \
                                                                                /mnt/rootfs/etc/init.d/* \
                                                            && tar czf /mnt/rootfs.tar.gz . -C /mnt/rootfs \
                                                            && rm -rf /mnt/rootfs"
}

while getopts "v:e:i:m:t:n:b:pfh" option
do
    case $option in
        v)
            ALPINE_VER="$OPTARG"
        ;;
        e)
            for i in $OPTARG; do
                DOCKER_ENV="${DOCKER_ENV} --env $i"
                DOCKER_ENV_BUILD="${DOCKER_ENV_BUILD} --build-arg $i"
            done
        ;;
        i)
            PACKAGES="$OPTARG"
        ;;
        m)
            MIRROR="$OPTARG"
        ;;
        t)
            IMAGE_NAME="$OPTARG"
        ;;
        b)
            BUILD="true"
            BUILD_NAME="$OPTARG"
        ;;
        p)
            PUSH="true"
        ;;
        f)
            FORCE="true"
            UPDATE="true"
        ;;
        h)
            f_usage
            exit 0
        ;;
    esac
done

f_gen_dockerfile() {
    echo -e "FROM scratch\nMAINTAINER xataz <https://github.com/xataz>\n\nADD rootfs.tar.gz /\n\nCMD [\"sh\"]" > ${SCRIPT_PATH}/${ALPINE_VER}/Dockerfile
}

## Check if version exist
curl ${MIRROR}/ 2> /dev/null | grep ${ALPINE_VER} > /dev/null 2>&1
[ $? -ne 0 ] && (f_log ERR "Build ${BUILD_NAME}:${ALPINE_VER} failed"; exit 1)

if [ "${FORCE}" != "true" ]; then
    f_check_maj
fi
if [ "${UPDATE}" == "true" ]; then
    f_gen_repos
    f_gen_rootfs
    f_gen_dockerfile
    if [ "${BUILD}" == "true" ]; then
        f_log INF "Build ${BUILD_NAME}:${ALPINE_VER}"
        docker build ${DOCKER_ENV_BUILD} -t ${BUILD_NAME}:${ALPINE_VER} ${SCRIPT_PATH}/${ALPINE_VER} > /dev/null 2>&1
        [ $? -eq 0 ] && f_log INF "Build ${BUILD_NAME}:${ALPINE_VER} done" || (f_log ERR "Build ${BUILD_NAME}:${ALPINE_VER} failed"; exit 1)
        if [ "${PUSH}" == "true" ]; then
            f_log INF "Push ${BUILD_NAME}:${ALPINE_VER}"
            docker push ${BUILD_NAME}:${ALPINE_VER} > /dev/null 2>&1
            [ $? -eq 0 ] && f_log INF "Push ${BUILD_NAME}:${ALPINE_VER} done" || (f_log ERR "Push ${BUILD_NAME}:${ALPINE_VER} failed"; exit 1)
            if [ "${LATEST}" == "${ALPINE_VER}" ]; then
                docker tag ${BUILD_NAME}:${ALPINE_VER} ${BUILD_NAME}:latest > /dev/null 2>&1
                f_log INF "Push ${BUILD_NAME}:latest"
                docker push ${BUILD_NAME}:latest > /dev/null 2>&1
                [ $? -eq 0 ] && f_log INF "Push ${BUILD_NAME}:latest done" || (f_log ERR "Push ${BUILD_NAME}:latest failed"; exit 1)
            fi
        fi
    fi
fi