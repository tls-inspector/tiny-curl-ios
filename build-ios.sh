#!/bin/sh
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <CURL Version>"
    exit 1
fi

############
# DOWNLOAD #
############

VERSION=$1
ARCHIVE=tiny-curl.tar.gz
if [ ! -f "${ARCHIVE}" ]; then
    echo "Downloading curl ${VERSION}"
    curl "https://curl.se/tiny/tiny-curl-${VERSION}.tar.gz" > "${ARCHIVE}"
fi

###########
# COMPILE #
###########

export OUTDIR=output
export BUILDDIR=build
export IPHONEOS_DEPLOYMENT_TARGET="12.0"

function build() {
    ARCH=$1
    HOST=$2
    SDKDIR=$3
    LOG="../${ARCH}_build.log"
    echo "Building libcurl for ${ARCH}..."

    WORKDIR=curl_${ARCH}
    mkdir "${WORKDIR}"
    tar -xzf "../${ARCHIVE}" -C "${WORKDIR}" --strip-components 1
    cd "${WORKDIR}"

    for FILE in $(find ../../patches -name '*.patch' 2>/dev/null); do
        patch -p1 < ${FILE}
    done

    unset CFLAGS
    unset LDFLAGS
    CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${SDKDIR} -I${SDKDIR}/usr/include -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET}"
    LDFLAGS="-arch ${ARCH} -isysroot ${SDKDIR}"
    export CFLAGS
    export LDFLAGS
    ./configure --host="${HOST}-apple-darwin" \
       --disable-shared \
       --enable-static \
       --without-libidn2 \
       --without-nghttp2 \
       --without-nghttp3 \
       --with-secure-transport > "${LOG}" 2>&1
    make -j`sysctl -n hw.logicalcpu_max` >> "${LOG}" 2>&1
    cp lib/.libs/libcurl.a ../../$OUTDIR/libcurl-${ARCH}.a
    cd ../
}

rm -rf $OUTDIR $BUILDDIR
mkdir $OUTDIR
mkdir $BUILDDIR
cd $BUILDDIR

build arm64    arm     `xcrun --sdk iphoneos --show-sdk-path`
build x86_64   x86_64  `xcrun --sdk iphonesimulator --show-sdk-path`

cd ../

rm ${ARCHIVE}

lipo \
   -arch arm64  $OUTDIR/libcurl-arm64.a \
   -arch x86_64 $OUTDIR/libcurl-x86_64.a \
   -create -output $OUTDIR/libcurl_all.a

###########
# PACKAGE #
###########

FWNAME=curl

if [ -d $FWNAME.framework ]; then
    echo "Removing previous $FWNAME.framework copy"
    rm -rf $FWNAME.framework
fi

LIBTOOL_FLAGS="-static"

echo "Creating $FWNAME.framework"
mkdir -p $FWNAME.framework/Headers
libtool -no_warning_for_no_symbols $LIBTOOL_FLAGS -o $FWNAME.framework/$FWNAME $OUTDIR/libcurl_all.a
cp -r $BUILDDIR/curl_arm64/include/$FWNAME/*.h $FWNAME.framework/Headers/

rm -rf $BUILDDIR
rm -rf $OUTDIR

cp "Info.plist" $FWNAME.framework/Info.plist
