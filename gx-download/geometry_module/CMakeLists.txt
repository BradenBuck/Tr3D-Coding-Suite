CMAKE_MINIMUM_REQUIRED (VERSION 2.8)

PROJECT (GEO_MODULE CXX)
SET (CMAKE_CXX_STANDARD_LIBRARIES -lstdc++)
SET (CMAKE_CXX_FLAGS "-Wno-write-strings")

SET (INCLUDE_LIST "")
SET (LIBRARY_LINK_LIST "")

INCLUDE (FindPkgConfig)

PKG_CHECK_MODULES (NETCDF netcdf)
IF (NETCDF_FOUND)
  LIST (APPEND INCLUDE_LIST ${NETCDF_INCLUDEDIR})
  FOREACH (NETCDF_LIB_IND ${NETCDF_LINK_LIBRARIES})
    LIST (APPEND LIBRARY_LINK_LIST ${NETCDF_LIB_IND})
    MESSAGE ("${NETCDF_LIB_IND}")
  ENDFOREACH ()
  LIST (APPEND LIBRARY_LINK_LIST /opt/local/lib/libnetcdff.a)
ENDIF ()

PKG_CHECK_MODULES (GSL gsl)
IF (GSL_FOUND)
  MESSAGE ("${GSL_INCLUDEDIR}/gsl")
  LIST (APPEND INCLUDE_LIST ${GSL_INCLUDEDIR}/gsl)
  FOREACH (GSL_LIB_IND ${GSL_LINK_LIBRARIES})
    LIST (APPEND LIBRARY_LINK_LIST ${GSL_LIB_IND})
    MESSAGE ("${GSL_LIB_IND}")
  ENDFOREACH ()
  LIST (APPEND LIBRARY_LINK_LIST /opt/local/lib/libgsl.a)
ENDIF ()

FILE (GLOB SRC_FILES src/*.cpp)
FILE (GLOB HEADER_FILES include/*.h)

ADD_EXECUTABLE (convert_VMEC_to_GX ${SRC_FILES} ${HEADER_FILES})
TARGET_INCLUDE_DIRECTORIES (convert_VMEC_to_GX PUBLIC /home/mfmartin/proc_comments_gx/include PUBLIC ${INCLUDE_LIST} PUBLIC ${GEO_MODULE_SOURCE_DIR}/include)
TARGET_LINK_LIBRARIES (convert_VMEC_to_GX PUBLIC ${LIBRARY_LINK_LIST})
SET_PROPERTY (TARGET convert_VMEC_to_GX PROPERTY CXX_STANDARD 11)
SET_TARGET_PROPERTIES (convert_VMEC_to_GX PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${GEO_MODULE_SOURCE_DIR})
