#!/bin/bash

##############################################################################
#
# Copyright: (C) 2011 RobotCub Consortium
# Authors: Paul Fitzpatrick
# CopyPolicy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT
#
# Amalgamate builds into an NSIS package
# 
# Command line arguments: 
#   build_yarp_core_package.sh ${OPT_COMPILER} ${OPT_VARIANT} ${OPT_BUILD}
# Example:
#   build_yarp_core_package.sh v10 x86 Release
#   build_yarp_core_package.sh v10 x86 any
#     (if OPT_BUILD is specified as any, Debug and Release are merged
#      in a single package)
#
# Inputs:
#   settings.sh (general configuration)
#      see process_options.sh for files read based on settings.sh
#   $SETTINGS_BUNDLE_FILENAME
#      read versions of software from file specified in settings.sh
#   ace_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh
#      ace paths - if OPT_BUILD is "any", both "Debug" and "Release" checked
#   yarp_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh
#      yarp paths - if OPT_BUILD is "any", both "Debug" and "Release" checked
#   nsis_any_any_any.sh
#      nsis paths
#   gtkmm_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh
#      gtkmm paths - an OPT_BUILD value of "any" is replaced with "Release"
#   qt_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh
#      Qt paths - an OPT_BUILD value of "any" is replaced with "Release"
#
# Related code:
#   src/nsis/yarp_core_package.nsi
#      This is the NSIS code for the installer.  It refers to generated
#      files for installing and uninstalling individual components
#      (see Outputs).
#
# Outputs:
#   yarp_core_package_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh
#      path to the installer and zip files produced
#   yarp_core_package-$BUNDLE_YARP_VERSION-$OPT_COMPILER-$OPT_VARIANT-$OPT_BUILD
#      build directory
#   [build directory]/*_remove.nsi
#      NSIS code fragment for installing each individual NSIS component
#   [build directory]/*_add.nsi
#      NSIS code fragment for uninstalling each individual NSIS component
#   [build directory]/*_zip.sh
#      scripts for generating zip files for each individual component
#      (this is not NSIS-related, but is convenient to do together
#      with NSIS since we have build lists of all the needed files)
#   [build directory]/*.exe
#      The generated installer
#   [build directory]/*.zip
#      Zip files for the individual components, plus everything combined.


BUILD_DIR=$PWD

BUNDLE_VENDOR=robotology

GUIS="yarpview yarpscope yarpmanager yarpdataplayer yarplogger yarpmotorgui"

# Get SETTINGS_* variables (paths) from cache
source ./settings.sh || {
  echo "No settings.sh found, are we in the build directory?"
  exit 1
}

# Get BUNDLE_* variables (software versions) from the bundle file
source $SETTINGS_BUNDLE_FILENAME || {
  echo "Bundle settings not found"
  exit 1
}

# GET OPT_* variables (build options) by processing our command-line options
source $SETTINGS_SOURCE_DIR/src/process_options.sh $* || {
  echo "Cannot process options"
  exit 1
}

# Figure out whether package will compile debug and release builds in one
if [ "k$OPT_BUILD" = "kany" ]; then
  base_build="Release"
  add_debug=true
else
  base_build="$OPT_BUILD"
  add_debug=false
fi
if $OPT_GCCLIKE; then
  add_debug=false
fi

# If we are combining debug build with release, we need to load and
# rename ACE and YARP paths for those builds
if $add_debug; then
  source ace_${OPT_COMPILER}_${OPT_VARIANT}_Debug.sh || {
    echo "Cannot find corresponding ACE debug build"
    exit 1
  }
  ACE_DIR_DBG="$ACE_DIR"
  ACE_ROOT_DBG="$ACE_ROOT"
  ACE_LIBNAME_DBG="$ACE_LIBNAME"

  source yarp_${OPT_COMPILER}_${OPT_VARIANT}_Debug.sh || {
    echo "Cannot find corresponding YARP debug build"
    exit 1
  }
  YARP_DIR_DBG="$YARP_DIR"
  YARP_ROOT_DBG="$YARP_ROOT"

# Removing GSL
  # source gsl_${OPT_COMPILER}_${OPT_VARIANT}_Debug.sh || {
    # echo "Cannot find corresponding GSL debug build"
    # exit 1
  # }
  # GSL_DIR_DBG="$GSL_DIR"
  # GSL_ROOT_DBG="$GSL_ROOT"
  source eigen_any_any_any.sh || {
    echo "Cannot find corresponding EIGEN build"
    exit 1
  }
fi

# Pick up ACE paths
source ace_${OPT_COMPILER}_${OPT_VARIANT}_${base_build}.sh || {
  echo "Cannot find corresponding ACE build"
  exit 1
}

# Pick up YARP paths
source yarp_${OPT_COMPILER}_${OPT_VARIANT}_${base_build}.sh || {
  echo "Cannot find corresponding YARP build"
  exit 1
}

# Removing GSL
# Pick up GSL paths
# source gsl_${OPT_COMPILER}_${OPT_VARIANT}_${base_build}.sh || {
  # echo "Cannot find corresponding GSL build"
  # exit 1
# }
source eigen_any_any_any.sh || {
  echo "Cannot find corresponding EIGEN build"
  exit 1
}

# Pick up GTKMM paths
GTKMM_VERSION_TAG="BUNDLE_GTKMM_VERSION_${OPT_COMPILER}_${OPT_VARIANT}"
if [ "${!GTKMM_VERSION_TAG}" != "" ]; then
  source gtkmm_${OPT_COMPILER}_${OPT_VARIANT}_${base_build}.sh || {
    echo "Cannot find corresponding GTKMM build"
    exit 1
  }
fi

# Pick up Qt paths
QT_VERSION_TAG="BUNDLE_QT_VERSION_${OPT_COMPILER}_${OPT_VARIANT}"
if [ "${!QT_VERSION_TAG}" != "" ]; then
  source qt_${OPT_COMPILER}_${OPT_VARIANT}_${base_build}.sh || {
  echo "Cannot find corresponding Qt build"
  exit 1
  }
fi

# Pick up Libjpeg paths
LIBJPEG_VERSION_TAG="BUNDLE_LIBJPEG_VERSION_${OPT_VARIANT}"
if [ "${!LIBJPEG_VERSION_TAG}" != "" ]; then
  source libjpeg_${OPT_VARIANT}_${base_build}.sh || {
  echo "Cannot find corresponding libjpeg-turbo build"
  exit 1
  }
fi


# Pick up OpenCV paths
OPENCV_VERSION_TAG="BUNDLE_OPENCV_VERSION"
if [ "${!OPENCV_VERSION_TAG}" != "" ]; then
  source opencv_${OPT_COMPILER}_${OPT_VARIANT}_${base_build}.sh || {
  echo "Cannot find corresponding openCV build"
  exit 1
  }
fi

# Pick up NSIS paths
source nsis_any_any_any.sh || {
  echo "Cannot find corresponding NSIS build"
  exit 1
}

# Make build directory
if [ "$BUNDLE_YARP_REVISION" != "" ]
then
  fname=yarp_core_package-${BUNDLE_YARP_REVISION}
elif [ "$BUNDLE_YARP_VERSION" != "" ]
then
  fname=yarp_core_package-${BUNDLE_YARP_VERSION}
else
  fname=yarp_core_package
fi
fname2=$fname-$OPT_COMPILER-$OPT_VARIANT-$OPT_BUILD
mkdir -p $fname2
cd $fname2 || exit 1
OUT_DIR=$PWD

# Clear any zip-related material
zip_name="$fname2"
rm -rf "$OUT_DIR/*_zip.sh"

# Function to prepare stub files for adding/removing files for an NSIS
# section, and for building the corresponding zip file
function nsis_setup {
  prefix=$1
  echo -n > ${OUT_DIR}/${prefix}_add.nsi
  echo -n > ${OUT_DIR}/${prefix}_remove.nsi
  #echo -n > ${OUT_DIR}/${prefix}_zip.sh
}

# Add a file or files into list to be added/removed from NSIS section,
# and to be placed into the corresponding zip file.  Implementation is
# complicated by the need to avoid calling the super-slow cygpath
# command too often.
CYG_BASE=`cygpath -w /`
function nsis_add_base {
  mode=$1
  prefix=$2
  src=$3
  dest=$4
  dir=$5 #optional
  echo "Add " "$@"
  osrc="$src"
  odest="$dest"
  if [ "$dir" == "" ]; then
    src="$PWD/$src"
    osrc="$src"
    src=${src//\//\\}
    src="$CYG_BASE$src"
  else
    src="$dir/$src"
    osrc="$src"
    src=${src//\//\\}
  fi
  dest=${dest//\//\\} # flip to windows convention
  zodest1="zip/$prefix/$zip_name/$odest"
  zodest2="zip_all/$zip_name/$odest"
  if [ "$mode" = "single" ]; then
    dir=`echo $dest | sed 's/\\\\[^\\\\]*$//'`
    echo "CreateDirectory \"\$INSTDIR\\$dir\"" >> $OUT_DIR/${prefix}_add.nsi
    echo "SetOutPath \"\$INSTDIR\"" >> $OUT_DIR/${prefix}_add.nsi
    echo "File /oname=$dest $src" >> $OUT_DIR/${prefix}_add.nsi
    echo "Delete \"\$INSTDIR\\$dest\"" >> $OUT_DIR/${prefix}_remove.nsi
    #echo "mkdir -p `dirname $zodest1`" >> $OUT_DIR/${prefix}_zip.sh
    #echo "mkdir -p `dirname $zodest2`" >> $OUT_DIR/${prefix}_zip.sh
    #echo "cp '$osrc' $zodest1" >> $OUT_DIR/${prefix}_zip.sh
    #echo "cp '$osrc' $zodest2" >> $OUT_DIR/${prefix}_zip.sh
  else
    # recursive
    dir=`echo $dest | sed 's/\\\\[^\\\\]*$//'`
    echo "CreateDirectory \"\$INSTDIR\\$dir\"" >> $OUT_DIR/${prefix}_add.nsi
    echo "SetOutPath \"\$INSTDIR\\$dir\"" >> $OUT_DIR/${prefix}_add.nsi
    echo "File /r $src" >> $OUT_DIR/${prefix}_add.nsi
    echo "RmDir /r \"\$INSTDIR\\$dest\"" >> $OUT_DIR/${prefix}_remove.nsi
    #echo "mkdir -p $zodest1" >> $OUT_DIR/${prefix}_zip.sh
    #echo "mkdir -p $zodest2" >> $OUT_DIR/${prefix}_zip.sh
    #echo "cp -r $osrc/* $zodest1" >> $OUT_DIR/${prefix}_zip.sh
    #echo "cp -r $osrc/* $zodest2" >> $OUT_DIR/${prefix}_zip.sh
  fi
}


# Add a single file into list to be added/removed from NSIS section,
# and to be placed into the corresponding zip file.
function nsis_add {
  nsis_add_base single "$@"
}

# Add a directory to be added/removed from NSIS section.
function nsis_add_recurse {
  nsis_add_base recurse "$@"
}

# Get base YARP path in unix format
YARP_DIR_UNIX=`cygpath -u $YARP_DIR`
if $add_debug; then
  YARP_DIR_DBG_UNIX=$(cygpath -u $YARP_DIR_DBG)
fi
# Removing GSL
#GSL_DIR_UNIX=`cygpath -u $GSL_DIR`
# if $add_debug; then
  # GSL_DIR_DBG_UNIX=`cygpath -u $GSL_DIR_DBG`
# fi
EIGEN_DIR_UNIX=$(cygpath -u $EIGEN_DIR)

# Set up stubs for all NSIS sections
nsis_setup ace_headers
nsis_setup ace_libraries
nsis_setup ace_dlls

# Removing GSL
#nsis_setup gsl_headers
#nsis_setup gsl_libraries
nsis_setup eigen_base

nsis_setup gtkmm_headers
nsis_setup gtkmm_libraries
nsis_setup gtkmm_dlls

nsis_setup yarp_base
nsis_setup yarp_libraries
nsis_setup yarp_dlls
nsis_setup yarp_headers
nsis_setup yarp_programs
nsis_setup yarp_math_libraries
nsis_setup yarp_math_dlls
nsis_setup yarp_math_headers
# Removing GTK GUIs
#nsis_setup yarp_gtk_guis
nsis_setup yarp_qt_guis

nsis_setup yarp_vc_dlls
nsis_setup yarp_examples

YARP_SUB="yarp-$BUNDLE_YARP_VERSION"
ACE_SUB="$ACE_PATH"
# Removing GSL
#GSL_SUB="gsl-$BUNDLE_GSL_VERSION"
EIGEN_SUB="eigen-$BUNDLE_EIGEN_VERSION"
GTKMM_SUB="$GTKMM_PATH"
QT_SUB="$QT_PATH"
LIBJPEG_SUB="$LIBJPEG_PATH"
OPENCV_SUB="$OPENCV_PATH"
_suffix="/install"
OPENCV_SUB=${OPENCV_SUB%$_suffix};

# Add YARP material to NSIS
cd $YARP_DIR_UNIX || exit 1
YARP_LICENSE="$YARP_ROOT/LICENSE"
cd $YARP_ROOT || exit 1
nsis_add yarp_base "LICENSE" ${YARP_SUB}/LICENSE
nsis_add yarp_base "COPYING" ${YARP_SUB}/COPYING
nsis_add yarp_base "LICENSE.Apache-2.0" ${YARP_SUB}/LICENSE.Apache-2.0
nsis_add yarp_base "LICENSE.BSD" ${YARP_SUB}/LICENSE.BSD
nsis_add yarp_base "LICENSE.GPL-2" ${YARP_SUB}/LICENSE.GPL-2
nsis_add yarp_base "LICENSE.GPL-3" ${YARP_SUB}/LICENSE.GPL-3
nsis_add yarp_base "LICENSE.LGPL-2.1" ${YARP_SUB}/LICENSE.GPL-2.1

# nsis_add yarp_base YARPConfigForInstall.cmake YARPConfig.cmake
cd $YARP_DIR_UNIX/install || exit 1
nsis_add_recurse yarp_base share ${YARP_SUB}/share
cd $YARP_DIR_UNIX/install/lib || exit 1

mkdir -p temp
cd temp
cp $YARP_DIR_UNIX/install/cmake/YARP*.cmake . || exit 1
#cp $YARP_DIR_UNIX/install/cmake/YARPConfig.cmake . || exit 1
#cp $YARP_DIR_UNIX/install/cmake/YARPConfigVersion.cmake . || exit 1
#cp $YARP_DIR_UNIX/install/cmake/YARPTargets.cmake . || exit 1
#cp $YARP_DIR_UNIX/install/cmake/YARPTargets-release.cmake . || exit 1

if ! $add_debug; then
  rm YARP*Targets-debug.cmake || exit 1
fi
#sed -i 's|[^"]*/YARPTargets.cmake|include(${CMAKE_CURRENT_LIST_DIR}/../lib/YARP/YARPTargets.cmake|' YARPConfig.cmake
#sed -i 's|[^"]*/install|${CMAKE_CURRENT_LIST_DIR}/..|g' YARPConfig.cmake

for f in ACE.lib libACE.dll ACEd.lib libACEd.dll; do
  sed -i "s|[^;]*/$f|\${_IMPORT_PREFIX}/../${ACE_SUB}/lib/$f|g" YARP*Targets-*.cmake
  done
  
#for k in release debug; do
#  if [ -e YARPTargets-$k.cmake ] ; then
## Removing GSL  
#    #for f in gsl.lib libgsl.a gslcblas.lib libgslcblas.a; do
#    #  sed -i "s|[^;]*/$f|\${_IMPORT_PREFIX}/../${GSL_SUB}/lib/$f|g" YARPTargets-$k.cmake
#    #done
#    for f in ACE.lib libACE.dll ACEd.lib libACEd.dll; do
#      sed -i "s|[^;]*/$f|\${_IMPORT_PREFIX}/../${ACE_SUB}/lib/$f|g" YARPTargets-$k.cmake
#    done
#  fi
#done
for f in `ls -1 *.cmake`; do
  nsis_add yarp_base $f ${YARP_SUB}/cmake/$f
done
#nsis_add yarp_base YARPConfigVersion.cmake ${YARP_SUB}/cmake/YARPConfigVersion.cmake
#nsis_add yarp_base YARPTargets.cmake ${YARP_SUB}/cmake/YARPTargets.cmake
#nsis_add yarp_base YARPConfig.cmake ${YARP_SUB}/cmake/YARPConfig.cmake
#nsis_add yarp_base YARPTargets-release.cmake ${YARP_SUB}/cmake/YARPTargets-release.cmake
#if $add_debug; then
#  nsis_add yarp_base YARPTargets-debug.cmake ${YARP_SUB}/cmake/YARPTargets-debug.cmake
#fi

cd $YARP_DIR_UNIX/install/lib || exit 1
for f in `ls -1 *.$LIBEXT | grep -v YARP_math`; do
  nsis_add yarp_libraries $f ${YARP_SUB}/lib/$f
done
for f in `ls -1 *.$LIBEXT | grep YARP_math`; do
  nsis_add yarp_math_libraries $f ${YARP_SUB}/lib/$f
done
nsis_add_recurse yarp_dlls yarp ${YARP_SUB}/lib/yarp
cd $YARP_DIR_UNIX/install/bin
for f in `ls -1 *.dll | grep -v YARP_math`; do
  nsis_add yarp_dlls $f ${YARP_SUB}/bin/$f
done
for f in `ls -1 *.dll | grep YARP_math`; do
  nsis_add yarp_math_dlls $f ${YARP_SUB}/bin/$f
done

BINARY_FILES=$(ls -1 *.exe)
for f in $BINARY_FILES; do
  if [ "${f/gtk}" == "$f" ]; then
    FOUND="false"
    for gui in $GUIS; do
      if [ "$f" == "${gui}.exe" ]; then
        FOUND="true"
      fi
    done
    if [ "$FOUND" != "true" ]; then
      nsis_add yarp_programs $f ${YARP_SUB}/bin/$f
    fi
   fi
done
cd $YARP_ROOT/example/hello
for f in `ls *.cpp CMakeLists.txt`; do
  nsis_add yarp_examples $f ${YARP_SUB}/example/$f
done

cd $YARP_DIR_UNIX/install/include/yarp
for f in conf os sig dev ; do
  nsis_add_recurse yarp_headers $f ${YARP_SUB}/include/yarp/$f
done
nsis_add_recurse yarp_math_headers math ${YARP_SUB}/include/yarp/math

# Removing GSL
# add GSL material
#cd $GSL_DIR_UNIX
#nsis_add_recurse gsl_headers include/gsl ${GSL_SUB}/include/gsl
#nsis_add_recurse gsl_libraries lib ${GSL_SUB}/lib
# add EIGEN material
cd $EIGEN_DIR_UNIX
nsis_add eigen_base signature_of_eigen3_matrix_library ${EIGEN_SUB}/signature_of_eigen3_matrix_library
nsis_add_recurse eigen_base Eigen ${EIGEN_SUB}/Eigen

# Add GTKMM material to NSIS
## 11/11/11: Lorenzo Natale. Added missing Visual Studio dlls from ${GTKMM_SUB}/bin
# Add GTKMM material to NSIS
if [ "$GTKMM_DIR" != "" ]; then
  ##cd $GTKMM_DIR/redist || exit 1
    cd $GTKMM_DIR/bin || exit 1
  for f in `ls -1 *.dll`; do
    chmod u+x $f
    nsis_add gtkmm_dlls $f ${GTKMM_SUB}/bin/$f
  done
  cd $GTKMM_DIR || exit 1
    nsis_add_recurse gtkmm_headers include ${GTKMM_SUB}/include
    nsis_add_recurse gtkmm_libraries lib ${GTKMM_SUB}/lib
  
  cd ${YARP_DIR_UNIX}/install/bin || exit 1
# Removing GTK GUIs
  # if [ "$QT_DIR" == "" ]; then
    # for f in $GUIS; do
      # if [ -f "${f}.exe" ]; then
        # nsis_add gtk_guis ${f}.exe ${YARP_SUB}/bin/${f}.exe
      # fi 
    # done
  # else
    # for f in $GUIS; do
      # if [ -f "${f}-gtk.exe" ]; then
        # nsis_add gtk_guis ${f}-gtk.exe ${YARP_SUB}/bin/${f}-gtk.exe
      # fi 
    # done
  # fi
# 03 jan 2013 by Matteo Brunettini : 
# Add Visual Studio re-distributable material to NSIS - Fix missign GTKMM MVSC100 DLLs
# NOTE: the path VS10/VC/redist/$OPT_VARIANT/Microsoft.VC100.CRT must be copied to VS10/VC/redist/$OPT_VARIANT/ 
  if [ "$OPT_VCNNN" == "VC110" ] || [ "$OPT_VCNNN" == "VC120" ]
  then
    echo "**** Fixing missing msvc100 DLLs in gtkmm from $REDIST_PATH/$OPT_VARIANT/Microsoft.VC100.CRT"
    VC_PLAT="$OPT_VARIANT"
    if [ "$VC_PLAT" == "amd64" ] || [ "$VC_PLAT" == "x86_amd64" ]
    then
      _PLAT_="x64"
    else
      _PLAT_="x86"
    fi
    cd "${REDIST_PATH}/${_PLAT_}/Microsoft.VC100.CRT" || exit 1
    for f in `ls *.dll`; do
      nsis_add yarp_vc_dlls $f ${YARP_SUB}/bin/$f "${REDIST_PATH}/${_PLAT_}/Microsoft.VC100.CRT"
    done
  fi
fi
if [ "$QT_DIR" != "" ]; then
  cd $QT_DIR || exit 1
  nsis_add_recurse qt_files bin ${QT_SUB}/bin
  if [ -f "${QT_SUB}/imports" ]; then
    nsis_add_recurse qt_files imports ${QT_SUB}/imports
  fi
  nsis_add_recurse qt_files include ${QT_SUB}/include
  nsis_add_recurse qt_files lib ${QT_SUB}/lib
  nsis_add_recurse qt_files mkspecs ${QT_SUB}/mkspecs
  nsis_add_recurse qt_files phrasebooks ${QT_SUB}/phrasebooks
  nsis_add_recurse qt_files plugins ${QT_SUB}/plugins
  nsis_add_recurse qt_files qml ${QT_SUB}/qml
  if [ -f "${QT_SUB}/resources" ]; then
    nsis_add_recurse qt_files resources ${QT_SUB}/resources
  fi
  nsis_add_recurse qt_files translations ${QT_SUB}/translations
  
  cd ${YARP_DIR_UNIX}/install/bin || exit 1
  for f in $GUIS; do
    nsis_add qt_guis ${f}.exe ${YARP_SUB}/bin/${f}.exe
  done
  
  cd ${YARP_DIR_UNIX}/install/lib || exit 1
  nsis_add_recurse qt_guis qt5 ${YARP_SUB}/lib/qt5
fi

# Add LIBJEPG-TURBO material to NSIS
if [ "$LIBJPEG_DIR" != "" ]; then
  cd $LIBJPEG_DIR || exit 1
  nsis_add_recurse libjpeg_files bin ${LIBJPEG_SUB}/bin
  nsis_add_recurse libjpeg_files bin ${LIBJPEG_SUB}/classes
  nsis_add_recurse libjpeg_files bin ${LIBJPEG_SUB}/doc
  nsis_add_recurse libjpeg_files bin ${LIBJPEG_SUB}/include
  nsis_add_recurse libjpeg_files bin ${LIBJPEG_SUB}/lib
fi

# OPENCV material to NSIS
if [ "$OPENCV_DIR" != "" ]; then  
  echo "Adding OPenCV material from $OPENCV_DIR"
  cd $OPENCV_DIR || exit 1
  nsis_add_recurse opencv_files include ${OPENCV_SUB}/include
  nsis_add_recurse opencv_files etc/haarcascades ${OPENCV_SUB}/etc/haarcascades
  nsis_add_recurse opencv_files etc/lbpcascades ${OPENCV_SUB}/etc/lbpcascades
  nsis_add_recurse opencv_files etc/licenses ${OPENCV_SUB}/etc/licenses
  nsis_add opencv_files LICENSE ${OPENCV_SUB}/LICENSE
  nsis_add opencv_files OpenCVConfig.cmake  ${OPENCV_SUB}/OpenCVConfig.cmake
  nsis_add opencv_files OpenCVConfig-version.cmake  ${OPENCV_SUB}/OpenCVConfig-version.cmake
  case "$OPT_VARIANT" in
  "x86" )
    OPENCV_OBJ_PLAT="x86"
    ;;
  "x64" | "x86_64" | "x86_amd64" )
    OPENCV_OBJ_PLAT="x64"
    ;;
  *)
    echo "ERROR: platform '$OPT_VARIANT' not supported."
  # exit 1
  esac
  nsis_add_recurse opencv_files $OPENCV_OBJ_PLAT ${OPENCV_SUB}/${OPENCV_OBJ_PLAT}
fi

# Add ACE material to NSIS
cd $ACE_DIR/lib || exit 1
if [ ! -e $ACE_LIBNAME.dll ]; then
  echo "Cannot find $ACE_LIBNAME.dll in $PWD"
  exit 1
fi
nsis_add ace_libraries $ACE_LIBNAME.$LIBEXT ${ACE_SUB}/lib/$ACE_LIBNAME.$LIBEXT
nsis_add ace_libraries $ACE_LIBNAME.pdb ${ACE_SUB}/bin/$ACE_LIBNAME.pdb
nsis_add ace_dlls $ACE_LIBNAME.dll ${ACE_SUB}/bin/$ACE_LIBNAME.dll
cd $ACE_DIR/ace || exit 1
rm -rf tmp/ace
mkdir -p tmp/ace || exit 1
cp -r -v *.h *.inl *.cpp os_include tmp/ace || exit 1
nsis_add_recurse ace_headers tmp/ace ${ACE_SUB}/ace

# Add Visual Studio re-distributable material to NSIS
if [ -e "$OPT_VC_REDIST_CRT" ] ; then
  cd "$OPT_VC_REDIST_CRT" || exit 1
  pwd
  for f in `ls *.dll`; do
    nsis_add yarp_vc_dlls $f ${YARP_SUB}/bin/$f "$OPT_VC_REDIST_CRT"
  done
fi

# Add debug material to NSIS
DBG_HIDE="-"
if $add_debug; then
  cd $YARP_DIR_DBG_UNIX/install/lib || exit 1
  for f in `ls -1 *.lib`; do
    nsis_add yarp_libraries $f ${YARP_SUB}/lib/$f
  done
  nsis_add_recurse yarp_dlls yarp ${YARP_SUB}/lib/yarp
  cd $YARP_DIR_DBG_UNIX/install/bin || exit 1
  for f in `ls -1 *.dll`; do
    nsis_add yarp_dlls $f ${YARP_SUB}/bin/$f
  done
  cd $ACE_DIR_DBG || exit 1
  cd lib || exit 1
  if [ ! -e $ACE_LIBNAME_DBG.dll ]; then
    echo "Cannot find $ACE_LIBNAME_DBG.dll in $PWD"
    exit 1
  fi
  nsis_add ace_libraries ${ACE_LIBNAME_DBG}.${LIBEXT} ${ACE_SUB}/lib/${ACE_LIBNAME_DBG}.${LIBEXT}
  nsis_add ace_dlls ${ACE_LIBNAME_DBG}.dll ${ACE_SUB}/bin/${ACE_LIBNAME_DBG}.dll
    if [ -f "${ACE_LIBNAME_DBG}_dll.pdb" ]; then
        nsis_add ace_libraries ${ACE_LIBNAME_DBG}_dll.pdb ${ACE_SUB}/bin/${ACE_LIBNAME_DBG}.pdb
    else
        nsis_add ace_libraries ${ACE_LIBNAME_DBG}.pdb ${ACE_SUB}/bin/${ACE_LIBNAME_DBG}.pdb
    fi
  cd $YARP_DIR_DBG_UNIX/install/lib || exit 1
  # Removing GSL
  # cd $GSL_DIR_DBG_UNIX
  # rm -rf tmp_debug
  # mkdir -p tmp_debug
  # cp -R lib tmp_debug/debug
  # nsis_add_recurse gsl_libraries tmp_debug/debug ${GSL_SUB}/lib/debug
  DBG_HIDE=""
fi

# Run NSIS
cd $OUT_DIR
cp $SETTINGS_SOURCE_DIR/src/nsis/*.nsh .

echo " Creating NSIS installer package.."

# Removing GSL
#NSIS_PARAMETERS=" -DYARP_PLATFORM=$OPT_VARIANT -DVENDOR=$BUNDLE_VENDOR -DYARP_VERSION=$BUNDLE_YARP_VERSION -DYARP_SUB=$YARP_SUB -DGSL_VERSION=$BUNDLE_GSL_VERSION -DACE_SUB=$ACE_SUB -DGSL_SUB=$GSL_SUB -DBUILD_VERSION=${OPT_COMPILER}_${OPT_VARIANT}_${BUNDLE_TWEAK} -DYARP_LICENSE=$YARP_LICENSE -DNSIS_OUTPUT_PATH=$(cygpath -w $PWD)"
NSIS_PARAMETERS=" -DYARP_PLATFORM=$OPT_VARIANT -DVENDOR=$BUNDLE_VENDOR -DYARP_VERSION=$BUNDLE_YARP_VERSION -DYARP_SUB=$YARP_SUB -DEIGEN_VERSION=$BUNDLE_EIGEN_VERSION -DACE_SUB=$ACE_SUB -DEIGEN_SUB=$EIGEN_SUB -DBUILD_VERSION=${OPT_COMPILER}_${OPT_VARIANT}_${BUNDLE_TWEAK} -DYARP_LICENSE=$YARP_LICENSE -DNSIS_OUTPUT_PATH=$(cygpath -w $PWD)"

if [ "$GTKMM_SUB" != "" ]; then
  NSIS_PARAMETERS="${NSIS_PARAMETERS} -DGTKMM_SUB=$GTKMM_SUB"
fi
if [ "${QT_SUB}" != "" ]; then
  NSIS_PARAMETERS="${NSIS_PARAMETERS} -DQT_SUB=$QT_SUB"
fi

if [ "${LIBJPEG_SUB}" != "" ]; then
  NSIS_PARAMETERS="${NSIS_PARAMETERS} -DLIBJPEG_SUB=$LIBJPEG_SUB"
fi

if [ "${OPENCV_SUB}" != "" ]; then
  NSIS_PARAMETERS="${NSIS_PARAMETERS} -DOPENCV_SUB=$OPENCV_SUB"
fi

$NSIS_BIN $NSIS_PARAMETERS "$(cygpath -m $SETTINGS_SOURCE_DIR/src/nsis/yarp_core_package.nsi)" || exit 1

PACKAGES_DEST_DIR="${BUILD_DIR}/yarp-packages" 
if [ ! -d "${PACKAGES_DEST_DIR}" ]; then
  mkdir ${PACKAGES_DEST_DIR}
fi

PACKAGE_FILE="yarp_${BUNDLE_YARP_VERSION}_${OPT_COMPILER}_${OPT_VARIANT}_${BUNDLE_TWEAK}.exe"
if [ -f "${PACKAGES_DEST_DIR}/${PACKAGE_FILE}" ]; then
  rm ${PACKAGES_DEST_DIR}/${PACKAGE_FILE}
fi
cp ${OUT_DIR}/${PACKAGE_FILE} ${PACKAGES_DEST_DIR}|| exit 1

# Cache paths and variables, for dependent packages to read
cd $OUT_DIR
(
  echo "export YARP_CORE_PACKAGE_DIR='$PWD'"
) > $BUILD_DIR/yarp_core_package_${OPT_COMPILER}_${OPT_VARIANT}_${OPT_BUILD}.sh
