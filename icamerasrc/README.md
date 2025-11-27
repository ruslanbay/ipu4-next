# Prerequisites

Before building the `icamerasrc` package, you must install the `libcamerahal` library. Follow the installation instructions provided in the [libcamerahal README](../libcamerahal/README.md).

# Build the icamerasrc package

# 1. Install requirements

```bash
sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

# 2. Configure icamerasrc

```bash
cd icamerasrc

autoreconf --install

CPPFLAGS="-I$LIBCAMHAL_INSTALL_DIR/include/ -I$LIBCAMHAL_INSTALL_DIR/include/api -I$LIBCAMHAL_INSTALL_DIR/include/utils " \
LDFLAGS="-L$LIBCAMHAL_INSTALL_DIR/lib/" \
CFLAGS="-O2" CXXFLAGS="-O2" \
./configure ${CONFIGURE_FLAGS} --prefix=$ICAMERASRC_INSTALL_DIR DEFAULT_CAMERA=0
```

# 3. Build icamerasrc

```bash
make clean && make -j8
make rpm
```

# 4. Install icamerasrc

```bash
sudo rpm -ivh rpm/icamerasrc-1.0.0-*..x86_64.rpm --nodeps --force
```
