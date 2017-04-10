#!/usr/bin/env bash
APP=perl6
ID=org.perl6.rakudo

PWD=$(pwd)
sudo mkdir -p -v /rsu
sudo chown $(whoami):$(whoami) /rsu || exit
#cd /rsu
wget http://rakudo.org/downloads/star/rakudo-star-latest.tar.gz
tar -xf rakudo-star*.tar.gz || exit
cd rakudo-star* || exit
perl ./Configure.pl --prefix="/rsu" --backends=moar --gen-moar || exit
make || exit
make install || exit
cd /rsu || exit
find . -type f | xargs -I '{}' sed -i -e 's|/rsu|././|g' '{}'
mkdir -p usr
mv * ./usr
echo "Now you need to fix usr/bin/perl6 script"
cp $PWD/perl6 ./usr/bin/perl6
chmod +x ./usr/bin/perl6
mkdir -v "$APP.AppImage" || exit
cd install || exit
cp "$PWD/$ID.desktop" "./$APP.AppImage"
