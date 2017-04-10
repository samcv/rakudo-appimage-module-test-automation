#!/usr/bin/env bash
APP=perl6
ID=org.perl6.rakudo
ORIG_DIR="$(pwd)"
echo "ORIG_DIR=$ORIG_DIR APP=$APP ID=$ID"
#stage_1 () {
sudo mkdir -v /rsu || sudo rm -rfv /rsu && sudo mkdir -v /rsu
sudo chown -R $(whoami):$(whoami) /rsu || exit
sudo chmod 755 /rsu
if [ ! "$BLEAD" ]; then
    TAR_GZ=rakudo-star-latest.tar.gz
    check_tar () { gzip -tv $TAR_GZ; }
    # IF we already have the download, check its integrity, otherwise delete
    if [ -f $TAR_GZ ]; then
        check_tar || rm -fv $TAR_GZ
    fi
    if [ ! -f $TAR_GZ ]; then
        wget http://rakudo.org/downloads/star/$TAR_GZ
    fi
    printf "Checking the compressed file integrity.\n"
    gzip -tv $TAR_GZ
    tar -xf $TAR_GZ || exit
    cd "$(find . -name 'rakudo-star*' -type d)" || exit
    perl ./Configure.pl --prefix="/rsu" --backends=moar --gen-moar || exit
else
    if [ -d 'rakudo' ]; then
        cd 'rakudo' && git pull
    else
        git clone https://github.com/rakudo/rakudo.git || exit
        cd rakudo || exit
    fi
    perl Configure.pl --prefix="/rsu" --gen-moar --gen-nqp --backends=moar || exit
fi
make || exit
make install || exit
cd /rsu || exit
echo "Replacing path in binaries"
find . -type f | xargs -I '{}' sed -i -e 's|/rsu|././|g' '{}'
mkdir -p -v usr
# AppImage documentation is bad. We must install into some directory (handpaths get coded into one directory), and then we need to then MOVE them to a new folder usr
# If we don't move everything to usr (even though we didn't do --prefix for that) paths won't match up and it won't start
mv * ./usr
echo "Now you need to fix usr/bin/perl6 script"
cp -v "$ORIG_DIR/perl6" ./usr/bin/perl6
chmod -v +x ./usr/bin/perl6
mkdir -v "$APP.AppDir"
#cd -v "$APP.AppDir"
cp -v "$ORIG_DIR/$ID.desktop" "./$APP.AppDir"
# TODO use `install` instead of mkdir and other things to be more correct
mkdir -p -v ./usr/share/metainfo/
cp -v "$ORIG_DIR/$ID.appdata.xml" ./usr/share/metainfo/
# Ok, everything should be READY by this point XXX move things into place
mv -v * "./$APP.AppDir"
# Move the image icon into place
cp -v "$ORIG_DIR/$APP.png" "./$APP.AppDir"

# Download the appimage tool which actually makes the Appimages
wget --tries=5 "https://github.com/probonopd/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod -v a+x appimagetool-x86_64.AppImage
wget --tries=5 "https://github.com/probonopd/AppImageKit/releases/download/continuous/AppRun-x86_64"
chmod -v a+x AppRun-x86_64
mv -v  AppRun-x86_64 "$APP.AppDir/AppRun"
# AppImage tools are dumb and refuse to create the appimage, if this happens,
# and it will, try again with -n option to force it
./appimagetool-x86_64.AppImage -v "$APP.AppDir" || ./appimagetool-x86_64.AppImage -v -n "$APP.AppDir"
IMAGE_NAME="$(find . -name '*perl6*.AppImage')"
mv "$IMAGE_NAME" "$ORIG_DIR"
cp -r "$APP.AppDir" "$ORIG_DIR"
cd "$ORIG_DIR" || exit
echo "Testing if $IMAGE_NAME --version works"
eval "$IMAGE_NAME --version"
RETURN_CODE=$?

if [ $RETURN_CODE == 0 ]; then
  echo -n
    #sudo rm -rf /rsu
fi
echo "Image build as $IMAGE_NAME"
exit $RETURN_CODE
