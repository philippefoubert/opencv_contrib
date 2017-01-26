# By default, we use built-in protobuf sources and pre-generated .proto files
# Note: In case of .proto model updates these variables should be used:
# - PROTOBUF_PROTOC_EXECUTABLE (required)
# - PROTOBUF_INCLUDE_DIR
# - PROTOBUF_LIBRARIES or PROTOBUF_LIBRARY / PROTOBUF_LIBRARY_DEBUG for find_package()
OCV_OPTION(BUILD_PROTOBUF "Force to build libprotobuf from sources" ON)
OCV_OPTION(UPDATE_PROTO_FILES "Force to rebuild .proto files" OFF)

if(UPDATE_PROTO_FILES)
  if(NOT DEFINED PROTOBUF_PROTOC_EXECUTABLE)
    find_package(Protobuf QUIET)
  endif()
  if(DEFINED PROTOBUF_PROTOC_EXECUTABLE AND EXISTS ${PROTOBUF_PROTOC_EXECUTABLE})
    message(STATUS "The protocol buffer compiler is found (${PROTOBUF_PROTOC_EXECUTABLE})")
    file(GLOB proto_files src/tensorflow/*.proto)
    list(APPEND proto_files src/caffe/caffe.proto)
    PROTOBUF_GENERATE_CPP(PROTOBUF_HDRS PROTOBUF_SRCS ${proto_files})
  else()
    message(FATAL_ERROR "The protocol buffer compiler is not found (PROTOBUF_PROTOC_EXECUTABLE='${PROTOBUF_PROTOC_EXECUTABLE}')")
  endif()
endif()

if(NOT BUILD_PROTOBUF AND NOT (DEFINED PROTOBUF_INCLUDE_DIR AND DEFINED PROTOBUF_LIBRARIES))
  find_package(Protobuf QUIET)
endif()

if(PROTOBUF_FOUND)
  # nothing
else()
  include(${CMAKE_CURRENT_LIST_DIR}/download_protobuf.cmake)
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/protobuf ${CMAKE_BINARY_DIR}/3rdparty/protobuf)
  set(PROTOBUF_LIBRARIES libprotobuf)
  set(PROTOBUF_INCLUDE_DIR ${PROTOBUF_CPP_PATH}/protobuf-3.1.0/src)
endif()

if(NOT UPDATE_PROTO_FILES)
  file(GLOB fw_srcs ${CMAKE_CURRENT_SOURCE_DIR}/misc/tensorflow/*.cc)
  file(GLOB fw_hdrs ${CMAKE_CURRENT_SOURCE_DIR}/misc/tensorflow/*.h)
  list(APPEND fw_srcs ${CMAKE_CURRENT_SOURCE_DIR}/misc/caffe/caffe.pb.cc)
  list(APPEND fw_hdrs ${CMAKE_CURRENT_SOURCE_DIR}/misc/caffe/caffe.pb.h)
  list(APPEND PROTOBUF_SRCS ${fw_srcs})
  list(APPEND PROTOBUF_HDRS ${fw_hdrs})
  list(APPEND PROTOBUF_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/misc/caffe)
  list(APPEND PROTOBUF_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/misc/tensorflow)
endif()

add_definitions(-DHAVE_PROTOBUF=1)

#supress warnings in autogenerated caffe.pb.* files
ocv_warnings_disable(CMAKE_CXX_FLAGS
    -Wunused-parameter -Wundef -Wignored-qualifiers -Wno-enum-compare
    -Wdeprecated-declarations
    /wd4125 /wd4267 /wd4127 /wd4244 /wd4512 /wd4702
    /wd4456 /wd4510 /wd4610 /wd4800
    -wd858 -wd2196
)
