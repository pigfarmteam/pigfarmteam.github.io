
## For Dev

``` bash
# install dependencies
npm install

# serve with hot reload at localhost:8080
npm run dev

# build for github page or deploy on simple server
bash build.sh
```

## Run bot operator
``` bash
npm start
```

fix node-gym
https://stackoverflow.com/questions/21155922/error-installing-node-gyp-on-ubuntu
1.First of all, install the "make" build tool in Ubuntu with the following commands:

sudo apt-get update && \
sudo apt-get install build-essential software-properties-common -y;


2. Then you need to install the a proper C/C++ compiler toolchain. We will be installing GCC here with the following commands:

sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
sudo apt-get update && \
sudo apt-get install gcc-snapshot -y && \
sudo apt-get update && \
sudo apt-get install gcc-6 g++-6 -y && \
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 60 --slave /usr/bin/g++ g++ /usr/bin/g++-6 && \
sudo apt-get install gcc-4.8 g++-4.8 -y && \
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.8;
3. Install python 2.7 version. (Note: Python 3 is not supported by node-gyp).

sudo apt update
sudo apt upgrade
sudo apt install python2.7 python-pip
4. And finally install, node-gyp npm package:

npm install -g node-gyp
Additional but not important: If you have any atom keyboard-layout related issue with node-gyp then install the following one more package:

sudo apt-get install libxkbfile-dev
Thats all! It should be working fine now.

