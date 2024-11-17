# Minimum required version of CMake
cmake_minimum_required(VERSION 3.10)

# Project name and version
project(SubZero VERSION 1.0 LANGUAGES C CXX) # Explicitly enable both C and C++

# Set the C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF) # Ensure strict adherence to the C++ standard

# Define build options
option(WERROR "Enable -Werror compiler flag" OFF)
option(PROBES "Enable probes" OFF)
option(CONFIG_NEED_CLOCK_GETTIME "Enable clock_gettime compatibility" OFF)

# Include directories
include_directories(
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/lib/stringencoders
    ${PROJECT_SOURCE_DIR}/tools/include
)

# External dependencies using pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBXML2 REQUIRED libxml-2.0)
pkg_check_modules(GLIB2 REQUIRED glib-2.0)

include_directories(${LIBXML2_INCLUDE_DIRS} ${GLIB2_INCLUDE_DIRS})
link_directories(${LIBXML2_LIBRARY_DIRS} ${GLIB2_LIBRARY_DIRS})

# Additional libraries
set(EXTRA_LIBS ${LIBXML2_LIBRARIES} ${GLIB2_LIBRARIES} z event ncurses)

# Platform-specific definitions and libraries
if(UNIX AND NOT APPLE)
    add_definitions(-D_GNU_SOURCE)
    list(APPEND EXTRA_LIBS rt)
endif()

if(APPLE)
    if(${CMAKE_SYSTEM_VERSION} VERSION_LESS "12.0")
        set(CONFIG_NEED_CLOCK_GETTIME ON)
        include_directories(/usr/local/include)
        link_directories(/usr/local/lib)
    endif()
endif()

# Compiler flags
set(EXTRA_WARNINGS
    -Wcast-align
    -Wformat
    -Wformat-security
    -Wformat-y2k
    -Wshadow
    -Winit-self
    -Wredundant-decls
    -Wswitch-default
    -Wno-system-headers
    -Wundef
    -Wwrite-strings
    -Wbad-function-cast
    -Wmissing-declarations
    -Wmissing-prototypes
    -Wnested-externs
    -Wold-style-definition
    -Wstrict-prototypes
)

if(WERROR)
    add_compile_options(-Werror)
endif()

add_compile_options(
    -Wall
    ${EXTRA_WARNINGS}
    -g
    -O3
    -fPIC
    -std=gnu99
)

if(CONFIG_NEED_CLOCK_GETTIME)
    add_definitions(-DCONFIG_NEED_CLOCK_GETTIME=1)
    set(COMPAT_SOURCES lib/compat/clock_gettime.c)
endif()

if(PROBES)
    add_definitions(-DCONFIG_PROBES)
    set(PROBE_SOURCES lib/probes.c)
endif()

# Generate protocol source and header files from .dialect files
file(GLOB DIALECT_FILES "lib/proto/*.dialect")
set(GENERATED_PROTO_SOURCES)
set(GENERATED_PROTO_HEADERS)

foreach(dialect_file ${DIALECT_FILES})
    get_filename_component(dialect_name ${dialect_file} NAME_WE)
    set(header_file "${PROJECT_SOURCE_DIR}/include/libtrading/proto/${dialect_name}.h")
    set(source_file "${PROJECT_SOURCE_DIR}/lib/proto/${dialect_name}.c")

    add_custom_command(
        OUTPUT ${source_file} ${header_file}
        COMMAND python3 ${PROJECT_SOURCE_DIR}/tools/fix/fixdialectc
            --input ${dialect_file}
            --header-path ${PROJECT_SOURCE_DIR}/include/libtrading/proto/
            --source-path ${PROJECT_SOURCE_DIR}/lib/proto/
        DEPENDS ${dialect_file} tools/fix/fixdialectc
        COMMENT "Generating protocol files for ${dialect_name}"
    )
    list(APPEND GENERATED_PROTO_SOURCES ${source_file})
    list(APPEND GENERATED_PROTO_HEADERS ${header_file})
endforeach()

# Manually list protocol source files that are not generated
set(MANUAL_PROTO_SOURCES
    lib/proto/fix_message.c
    lib/proto/fix_session.c
    lib/proto/fix_template.c
    lib/proto/fast_message.c
    lib/proto/fast_session.c
    lib/proto/fast_template.c
    lib/proto/soupbin3_session.c
    lib/proto/ouch42_message.c
    lib/proto/omx_itch186_message.c
    lib/proto/lse_itch_message.c
    lib/proto/nasdaq_itch40_message.c
    lib/proto/nasdaq_itch41_message.c
    lib/proto/nasdaq_itch50_message.c
    lib/proto/bats_pitch_message.c
    lib/proto/boe_message.c
    lib/proto/mbt_quote_message.c
    lib/proto/xdp_message.c
)

set(PROTO_SOURCES
    ${GENERATED_PROTO_SOURCES}
    ${MANUAL_PROTO_SOURCES}
)

# Collect all protocol headers
file(GLOB PROTO_HEADERS "include/libtrading/proto/*.h")

# Gather library source files
set(LIB_SOURCES
    lib/itoa.c
    lib/buffer.c
    lib/order_book.c
    lib/mmap-buffer.c
    lib/read-write.c
    lib/stringencoders/modp_numtoa.c
    ${PROTO_SOURCES}
    ${COMPAT_SOURCES}
    ${PROBE_SOURCES}
)

if(NOT LIB_SOURCES)
    message(FATAL_ERROR "No source files found in library sources!")
endif()

# Create static and shared libraries
add_library(trading_static STATIC ${LIB_SOURCES})
target_link_libraries(trading_static ${EXTRA_LIBS})
add_library(trading_shared SHARED ${LIB_SOURCES})
target_link_libraries(trading_shared ${EXTRA_LIBS})
set_target_properties(trading_shared PROPERTIES OUTPUT_NAME "trading")
set_target_properties(trading_shared PROPERTIES VERSION ${PROJECT_VERSION})

# Include directories for libraries
target_include_directories(trading_static PUBLIC lib/proto include)
target_include_directories(trading_shared PUBLIC lib/proto include)

# Library alias targets
add_library(SubZero::TradingStatic ALIAS trading_static)
add_library(SubZero::TradingShared ALIAS trading_shared)

# Install libraries
install(TARGETS trading_static trading_shared
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(FILES ${PROTO_HEADERS} DESTINATION include/libtrading)

# Add Google Test
include(FetchContent)

FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/release-1.12.1.zip
)

set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

enable_testing()

# Add unit tests
add_executable(unit_tests
    tests/unit_tests.cpp
)

target_link_libraries(unit_tests
    gtest_main
    trading_static
)

add_test(NAME UnitTests COMMAND unit_tests)

# Helper function for adding tool executables
function(add_tool_executable name)
    add_executable(${name} ${ARGN})
    target_link_libraries(${name} trading_static ${EXTRA_LIBS} m)
    target_include_directories(${name} PRIVATE ${PROJECT_SOURCE_DIR}/include)
    install(TARGETS ${name} RUNTIME DESTINATION bin)
endfunction()

# Executable targets with their source files
add_tool_executable(fix_client
    tools/fix/fix_client.c
    tools/fix/fix_common.c
    tools/fix/test.c
    lib/die.c
)

add_tool_executable(fix_server
    tools/fix/fix_server.c
    tools/fix/fix_common.c
    tools/fix/test.c
    lib/die.c
)

# Generate version file
add_custom_command(
    OUTPUT ${PROJECT_BINARY_DIR}/LIBTRADING-VERSION-FILE
    COMMAND sh ${PROJECT_SOURCE_DIR}/tools/gen-version-file > ${PROJECT_BINARY_DIR}/LIBTRADING-VERSION-FILE
    DEPENDS ${PROJECT_SOURCE_DIR}/tools/gen-version-file
    COMMENT "Generating LIBTRADING-VERSION-FILE"
)
add_custom_target(version-file ALL DEPENDS ${PROJECT_BINARY_DIR}/LIBTRADING-VERSION-FILE)

# libtrading-config executable
add_executable(libtrading-config libtrading-config.c)
add_dependencies(libtrading-config version-file)
target_compile_definitions(libtrading-config PRIVATE PREFIX=\"${CMAKE_INSTALL_PREFIX}\")
target_include_directories(libtrading-config PRIVATE ${PROJECT_SOURCE_DIR}/include)
install(TARGETS libtrading-config RUNTIME DESTINATION bin)
