User Guide 
#  1.  Setup build environment
##  System requirements:
      Ubuntu 21.04
      glib-2.0
      gobject-2.0
      gstreamer-1.0(Version 1.7.9 is preferred)
      autoconf
      libtool

##  Prerequisite packages:
      libcamhal

#  2.  Configure icamerasrc
      autoreconf --install
      CPPFLAGS="-I$LIBCAMHAL_INSTALL_DIR/include/ -I$LIBCAMHAL_INSTALL_DIR/include/api \
                -I$LIBCAMHAL_INSTALL_DIR/include/utils " LDFLAGS="-L$LIBCAMHAL_INSTALL_DIR/lib/" \
                CFLAGS="-O2" CXXFLAGS="-O2" \
              ./configure ${CONFIGURE_FLAGS} --prefix=$ICAMERASRC_INSTALL_DIR DEFAULT_CAMERA=0

#  3. Build icamerasrc
     make clean && make -j8
     make rpm (RPM package is generated in rpm/)

#  4. Install icamerasrc
     sudo rpm -ivh icamerasrc-*.rpm --nodeps --force



