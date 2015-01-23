#!/usr/bin/env bash

REPO=https://github.com/wkhtmltopdf/wkhtmltopdf.git
VERSION=0.12.2.1
ARCH=`uname -m`
CWD=$(pwd)

function clean {
  cd
  rm -rf ./wkhtmltopdf
  rm -rf /tmp/wkhtmltopdf
  rm -f wkhtmltopdf.deb
}

function usage {
  echo 'Usage: ./build-wkhtmltopdf [TARGET]'
  echo 'Targets:'
  echo '  clean      removes all created files, including compiled binaries'
  echo '             may not work with git!'
  echo '  deb        Creates .deb. Sources should be already compiled'
}

## Install deps
function deps {
  echo '[deps]'
  apt-get update
  apt-get install -y libxext-dev libxrender-dev libpng-dev zlib1g-dev libssl-dev libjpeg-dev libfreetype6-dev
}

function src {
  ## Download source code
  echo '[src]'
  ## Recommended to use home dir for build
  cd
  git clone --depth 1 --branch $VERSION --recursive $REPO
  ## TODO At least git 1.8.4 required
  # git submodule update --depth 1
}

function build {
  ## Build
  echo '[build]'
  ~/wkhtmltopdf/scripts/build.py posix-local
}

function pkg_prepare {
  echo '[prepare for packaging]'
  cd ~/wkhtmltopdf
  # cp binaries to /usr/local/bin
  #FIXME Ugly copypaste
  mkdir -p /tmp/wkhtmltopdf/usr/local/bin
  mkdir -p /tmp/wkhtmltopdf/usr/local/share
  mkdir -p /tmp/wkhtmltopdf/usr/local/lib

  cp ./static-build/posix-local/app/bin/wkhtmltopdf /tmp/wkhtmltopdf/usr/local/bin/

  # Create config
  mkdir -p /tmp/wkhtmltopdf/DEBIAN

  #TODO Minor: Installed size, vendor, etc
  cat >/tmp/wkhtmltopdf/DEBIAN/control <<EOL
Package: wkhtmltopdf
Version: ${VERSION}
License: LGPLv3
Vendor: wkhtmltopdf.org
Architecture: amd64
Maintainer: Ashish Kulkarni <kulkarni.ashish@gmail.com>
Installed-Size: 185520
Depends: fontconfig, libfontconfig1, libfreetype6, libpng12-0, zlib1g, libx11-6, libxext6, libxrender1, libstdc++6, libc6
Conflicts: wkhtmltopdf
Provides: wkhtmltopdf
Replaces: wkhtmltopdf
Section: utils
Priority: extra
Homepage: http://wkhtmltopdf.org
Description: convert HTML to PDF using QtWebkit
EOL
}

function pkg_create {
  echo '[create package]'
  # pack to ar/deb 
  cd /tmp
  dpkg-deb --build wkhtmltopdf

  # Move to CWD dir
  mv /tmp/wkhtmltopdf.deb $CWD
  echo "Package is in your working dir"
}

## -- SCRIPT STARTING POINT -- ##
## 'clean' target
if [ $# -gt 0 ]; then
  if [ $1 = "clean" ]; then
    clean
  elif [ $1 = "deb" ]; then
    pkg_prepare
    pkg_create
  else
    usage
  fi
  exit
fi

function status_check {
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    echo $1
    exit 1
  fi
}

## TODO Sudo required


## TASKS LIST:
deps
status_check 'Error while installing dependencies'

src
build
status_check 'Error while compiling sources'

pkg_prepare
pkg_create
status_check 'Error while creating debian package'

echo "Done!"

