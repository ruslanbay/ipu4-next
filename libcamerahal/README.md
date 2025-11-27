# Build and install the icamerasrc package

## 1 Install requirements

```bash
sudo apt-get install cmake rpm autoconf libtool linux-libc-dev
```

## 2. Copy ipu4 binary files to the build environment

```bash
sudo cp -rf IPU_binary/lib/* /lib
sudo cp -rf IPU_binary/usr/* /usr
```

## 3. Build the libcamerahal package

```bash
cd libcamerahal
mkdir build
cd build
cmake ../
make -j
make package
```

## 4. Install libcamhal

```bash
sudo rpm -ivh --force --nodeps libcamhal-1.0.0-Linux.rpm
```
