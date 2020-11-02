# https://github.com/Spectator-Health/opencv-docker
# Attempt at base image for OpenCV on RPi devices 
#FROM balenalib/raspberry-pi-python
#FROM balenalib/generic-armv7ahf-python
FROM balenalib/armv7hf-debian

ENV OPENCV_VERSION=4.4.0

# NOTE: removed libjasper-dev 
RUN echo "Installing dependencies..." && \
	apt-get -y --no-install-recommends update && \
	apt-get -y --no-install-recommends upgrade && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	apt-utils build-essential cmake wget git unzip pkg-config \ 
	libjpeg-dev libpng-dev libtiff-dev \
	libavcodec-dev libavformat-dev libswscale-dev \
	libgtk2.0-dev libcanberra-gtk* \
	libxvidcore-dev libx264-dev libgtk-3-dev \
	python3-dev python3-numpy python3-pip \
	python-dev python-numpy \
	libtbb2 libtbb-dev libdc1394-22-dev \
	libv4l-dev v4l-utils \
	libopenblas-dev libatlas-base-dev libblas-dev \
	liblapack-dev gfortran \
	gcc-arm* \
	protobuf-compiler \
	&& sudo rm -rf /var/lib/apt/lists/* 

RUN echo "Downloading OpenCV ..." && \
	wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
	wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \ 
	unzip opencv.zip && mv -f opencv-${OPENCV_VERSION} opencv && \ 
	unzip opencv_contrib.zip && mv -f opencv_contrib-${OPENCV_VERSION} opencv_contrib

RUN echo "Configuring OpenCV ..." && \ 
	cd opencv && mkdir build && cd build && \ 
	cmake \
		-D CMAKE_BUILD_TYPE=RELEASE \
		-D CMAKE_INSTALL_PREFIX=/usr/local \
		-D CMAKE_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
		-D ENABLE_NEON=ON \
		-D ENABLE_VFPV3=ON \
		-D WITH_OPENMP=ON \
		-D BUILD_TIFF=ON \
		-D WITH_FFMPEG=ON \
		-D WITH_GSTREAMER=ON \
		-D WITH_TBB=ON \
		-D BUILD_TESTS=OFF \
		-D WITH_EIGEN=OFF \
		-D ITH_V4L=ON \
		-D WITH_LIBV4L=ON \
		-D WITH_QT=OFF \
		-D WITH_VTK=OFF \
		-D OPENCV_EXTRA_EXE_LINKER_FLAGS=-latomic \
		-D OPENCV_ENABLE_NONFREE=ON \
		-D INSTALL_C_EXAMPLES=OFF \
		-D INSTALL_PYTHON_EXAMPLES=OFF \
		-D BUILD_NEW_PYTHON_SUPPORT=ON \
		-D BUILD_opencv_python3=TRUE \
		-D OPENCV_GENERATE_PCKCONFIG=ON \
		-D BUILD_EXAMPLES=OFF .. 

RUN echo "Making OpenCV ..." && \
	cd opencv/build && make -j$(nproc) && make install && ldconfig 

RUN echo "Verifying OpenCV ..." && \ 
	python3 -c "import cv2; print('Installed OpenCV version is: {}'.format(cv2.__version__))" && \ 
	if [ $? -eq 0 ]; then \
		echo "OpenCV installed successfully! ............." \
	else \
		echo "OpenCV installation failed :( .............." \
		exit 1; \
	fi 

RUN echo "Cleaning up ..." && \ 
	rm /opencv.zip && rm /opencv_contrib.zip 

RUN echo "Reboot system to finalize installation" 
