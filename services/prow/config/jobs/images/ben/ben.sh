#!/bin/sh

set -e

cp -r /usr/share/ben/media html/media
rm -f html/media/jquery.min.js
cp /usr/share/javascript/jquery/jquery.min.js html/media/

mkdir -p html/html
cp -r /usr/share/ben/media html/html/media
rm -f html/html/media/jquery.min.js
cp /usr/share/javascript/jquery/jquery.min.js html/html/media/

# ben download -v --suite beige --areas main --archs amd64,arm64,i386,loong64,riscv64 --mirror https://ci.deepin.com/repo/deepin/deepin-community/stable --preferred-compression-format gz

curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/stable/dists/beige/main/binary-amd64/Packages.gz | zcat > Packages_amd64
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/stable/dists/beige/main/binary-arm64/Packages.gz | zcat > Packages_arm64
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/stable/dists/beige/main/binary-i386/Packages.gz | zcat > Packages_i386
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/stable/dists/beige/main/binary-loong64/Packages.gz | zcat > Packages_loong64
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/stable/dists/beige/main/binary-riscv64/Packages.gz | zcat > Packages_riscv64
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/stable/dists/beige/main/source/Sources.gz | zcat > Sources

curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/testing/dists/unstable/main/binary-amd64/Packages.gz | zcat >> Packages_amd64
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/testing/dists/unstable/main/binary-arm64/Packages.gz | zcat >> Packages_arm64
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/testing/dists/unstable/main/binary-i386/Packages.gz | zcat >> Packages_i386
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/testing/dists/unstable/main/binary-loong64/Packages.gz | zcat >> Packages_loong64
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/testing/dists/unstable/main/binary-riscv64/Packages.gz | zcat >> Packages_riscv64
curl -fsSL https://ci.deepin.com/repo/deepin/deepin-community/testing/dists/unstable/main/source/Sources.gz | zcat >> Sources


# html/media
# html/index.html
# html/html/media
# html/html/trans1.html

ben tracker --run-debcheck -c config/global.conf -b html
