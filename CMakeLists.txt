# (C) Copyright 2017 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

#
# fv3-bundle
#

project( fv3-bundle C CXX Fortran )

cmake_minimum_required( VERSION 3.3.2 FATAL_ERROR )

set( CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake;${CMAKE_CURRENT_SOURCE_DIR}/ecbuild/cmake;${CMAKE_MODULE_PATH}")
include( ecbuild_bundle )

set( ENABLE_MPI ON CACHE BOOL "Compile with MPI" )

ecbuild_bundle_initialize()

ecbuild_requires_macro_version( 2.7 )

ecbuild_bundle( PROJECT eckit    GIT "https://github.com/UCAR/eckit.git"     BRANCH master         UPDATE )
ecbuild_bundle( PROJECT fckit    GIT "https://github.com/UCAR/fckit.git"     BRANCH master         UPDATE )
ecbuild_bundle( PROJECT oops     GIT "https://github.com/UCAR/oops.git"      BRANCH nicas-develop  UPDATE )

ecbuild_bundle( PROJECT crtm     GIT "https://github.com/JCSDA/crtm.git"     BRANCH master         UPDATE )
ecbuild_bundle( PROJECT ioda     GIT "https://github.com/JCSDA/ioda.git"     BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT ufo      GIT "https://github.com/JCSDA/ufo.git"      BRANCH develop        UPDATE )

ecbuild_bundle( PROJECT fms      GIT "https://github.com/JCSDA/fms.git"      BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT fv3      GIT "https://github.com/JCSDA/fv3.git"      BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT fv3-jedi GIT "https://github.com/JCSDA/fv3-jedi.git" BRANCH develop        UPDATE )

ecbuild_bundle_finalize()