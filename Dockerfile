FROM archlinux:latest

# install dependencies
RUN <<EOF
pacman -Sy --noconfirm base-devel libtiff libgphoto2 libjpeg libusb libcups libieee1284 v4l-utils avahi bash net-snmp git texlive-latexextra autoconf-archive wget curl unzip python libsoup ctags
wget "https://github.com/ast-grep/ast-grep/releases/download/0.21.1/sg-x86_64-unknown-linux-gnu.zip" -O sg.zip
unzip sg.zip
chmod +x sg
mv sg /usr/local/bin/ast-grep
EOF

# build SANE
# based on https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=sane-git
RUN <<EOF
git clone https://gitlab.com/sane-project/backends.git
cd backends
git switch --detach 0f472aa205f2cc90acb76a0471a377d60d14bb2b

ast-grep --pattern 'sane_get_devices($STRUCT, SANE_TRUE)' --rewrite 'sane_get_devices($STRUCT, SANE_FALSE)' --update-all --lang c frontend/saned.c
./autogen.sh
./configure --prefix=/usr \
    --sbindir=/usr/bin \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --with-docdir="/usr/share/doc/sane" \
    --enable-avahi \
    --enable-pthread \
    --disable-rpath \
    --enable-libusb_1_0 \
    --disable-locking \
    BACKENDS="epson" \
    PRELOADABLE_BACKENDS=""
make
make install
EOF

# build & install sane-airscan
# based on https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=sane-airscan-git
RUN <<EOF
git clone https://github.com/alexpevzner/sane-airscan
cd sane-airscan
git switch --detach 8735f70dfb0ff3f3a2262c9f31760607e5b94044
make install
EOF

# configure
RUN <<EOF
# enable any IP to connect
echo -e "\\n+\\n" >> /etc/sane.d/saned.conf
echo -e "data_portrange = 10000 - 10100\\n" >> /etc/sane.d/saned.conf

# disable all preloaded backends
echo "" >> /etc/sane.d/dll.conf

# configure airscan to know about the particular printers
cat >> /etc/sane.d/airscan.conf <<EF
[devices]
"BODLOK" = http://192.168.192.68/active/msu/scan, WSD
"LEJSEK" = http://192.168.192.67/active/msu/scan, WSD
[options]
discovery = disable
EF
EOF


# Add Tini
ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

EXPOSE 6566/tcp
CMD ["/usr/bin/saned", "-l", "-d128", "-e"]

