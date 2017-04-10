#!/usr/bin/env bash
APP=perl6
ID=org.perl6.rakudo

ORIG_DIR="$(pwd)"
echo $ORIG_DIR
sudo mkdir -p -v /rsu
sudo chown $(whoami):$(whoami) /rsu || exit
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
make || exit
make install || exit
cd /rsu || exit
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
wget "https://github.com/probonopd/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod -v a+x appimagetool-x86_64.AppImage
# AppImage tools are dumb and refuse to create the appimage, if this happens,
# and it will, try again with -n option to force it
./appimagetool-x86_64.AppImage -v "$APP.AppDir" || ./appimagetool-x86_64.AppImage -v -n "$APP.AppDir"
RETURN_CODE=$?
mv "$(find . -name '*perl6*.AppImage')" "$ORIG_DIR" || RETURN_CODE=$?
cd "$ORIG_DIR"
if [ $RETURN_CODE == 0 ]; then
    sudo rm -rf /rsu
fi
exit $RETURN_CODE
