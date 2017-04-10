#!/usr/bin/env bash
sudo -p mkdir /rsu
sudo chown $(whoami):$(whoami) /rsu || exit
#cd /rsu
tar -xf rakudo-star-*.tar.gz || exit
cd rakudo-star* || exit
perl ./Configure.pl --prefix="/rsu" --backends=moar --gen-moar || exit
make || exit
make install || exit
cd /rsu || exit
find . -type f | xargs -I '{}' sed -i -e 's|/rsu|././|g' '{}'
mkdir -p usr
mv * ./usr
echo "Now you need to fix usr/bin/perl6 script"

APP=perl6
ID=org.perl6.rakudo