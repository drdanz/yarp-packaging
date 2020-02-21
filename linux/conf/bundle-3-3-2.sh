#!/bin/bash

DEPENDENCIES_COMMON="qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev libqt5svg5 libtinyxml-dev libace-dev git cmake dpkg wget libeigen3-dev qml-module-qtquick2 qml-module-qtquick-window2 qml-module-qtmultimedia qml-module-qtquick-dialogs qml-module-qtquick-controls libjpeg-dev libopencv-dev libopenni2-dev portaudio19-dev libsdl1.2-dev libi2c-dev libv4l-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-tools libgraphviz-dev libsqlite3-dev libqcustomplot-dev"
# Leave empty if you don't use dependancies from backports otherwise fill the following with the line that add backports in the distro sources.list (platform dependant)
DEPENDENCIES_buster=""
DEPENDENCIES_bionic=""
#BACKPORTS_URL_wheezy="http://http.debian.net/debian"
export YARP_PACKAGE_VERSION=3.3.2
# always use a revision number >=1
export YARP_DEB_REVISION=1
YARP_CMAKE_OPTIONS="\
 -DYARP_COMPILE_GUIS=TRUE \
 -DCMAKE_INSTALL_PREFIX=/usr \
 -DYARP_COMPILE_libYARP_math=TRUE \
 -DENABLE_yarpcar_tcpros=TRUE \
 -DENABLE_yarpcar_rossrv=TRUE \
 -DENABLE_yarpcar_xmlrpc=TRUE \
 -DENABLE_yarpcar_bayer=TRUE \
 -DENABLE_yarpcar_priority=TRUE \
 -DENABLE_yarpcar_portmonitor=TRUE \
 -DENABLE_yarpcar_depthimage=TRUE \
 -DENABLE_yarpcar_mjpeg=TRUE \
 -DENABLE_yarpmod_Rangefinder2DClient=TRUE \
 -DENABLE_yarpmod_Rangefinder2DWrapper=TRUE \
 -DENABLE_yarpmod_SerialServoBoard=TRUE \
 -DENABLE_yarpmod_batteryClient=TRUE \
 -DENABLE_yarpmod_batteryWrapper=TRUE \
 -DENABLE_yarpmod_fakeAnalogSensor=TRUE \
 -DENABLE_yarpmod_fakeDepthCamera=TRUE \
 -DENABLE_yarpmod_fakeIMU=TRUE \
 -DENABLE_yarpmod_fakeLaser=TRUE \
 -DENABLE_yarpmod_fakeMotionControl=TRUE \
 -DENABLE_yarpmod_fakebot=TRUE \
 -DENABLE_yarpmod_laserFromDepth=TRUE \
 -DENABLE_yarpmod_localization2DClient=TRUE \
 -DENABLE_yarpmod_map2DClient=TRUE \
 -DENABLE_yarpmod_map2DServer=TRUE \
 -DENABLE_yarpmod_multipleanalogsensorsclient=TRUE \
 -DENABLE_yarpmod_multipleanalogsensorsremapper=TRUE \
 -DENABLE_yarpmod_multipleanalogsensorsserver=TRUE \
 -DENABLE_yarpmod_navigation2DClient=TRUE \
 -DENABLE_yarpmod_serialport=TRUE \
 -DENABLE_yarpmod_test_grabber=TRUE \
 -DENABLE_yarpmod_transformClient=TRUE \
 -DENABLE_yarpmod_transformServer=TRUE \
 -DYARP_priv_xmlrpcpp_TYPE=SHARED \
 -DYARP_COMPILE_yarplaserscannergui=TRUE \
 -DENABLE_yarpmod_depthCamera=TRUE \
 -DENABLE_yarpmod_fakeBattery=TRUE \
 -DENABLE_yarpmod_opencv_grabber=TRUE \
 -DENABLE_yarpmod_portaudio=TRUE \
 -DENABLE_yarpmod_portaudioPlayer=TRUE \
 -DENABLE_yarpmod_portaudioRecorder=TRUE \
 -DENABLE_yarpmod_fakeMicrophone=TRUE \
 -DENABLE_yarpmod_fakeSpeaker=TRUE \
 -DENABLE_yarpmod_SDLJoypad=TRUE \
 -DENABLE_yarpmod_imuBosch_BNO055=TRUE \
 -DENABLE_yarpmod_usbCamera=TRUE \
 -DENABLE_yarpmod_usbCameraRaw=TRUE \
 -DENABLE_yarpmod_fakeLocalizer=TRUE \
 -DENABLE_yarpmod_fakeNavigation=TRUE \
 -DENABLE_yarpcar_h264=TRUE \
 -DYARP_COMPILE_yarpviz=TRUE \
"