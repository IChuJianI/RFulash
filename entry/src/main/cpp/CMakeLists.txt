cmake_minimum_required(VERSION 3.5.0)
project(rfulash)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(NOT DEFINED OHOS_ARCH)
    set(OHOS_ARCH arm64-v8a)
endif()

add_library(entry SHARED napi_init.cpp)

target_link_libraries(entry PUBLIC libace_napi.z.so libace_ndk.z.so libhilog_ndk.z.so
    libnative_window.so)

set(RUFFLE_ENGINE_LIB
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../libs/${OHOS_ARCH}/libruffle_ohos_engine.so)
if(EXISTS ${RUFFLE_ENGINE_LIB})
    add_library(ruffle_engine SHARED IMPORTED)
    set_target_properties(ruffle_engine PROPERTIES IMPORTED_LOCATION ${RUFFLE_ENGINE_LIB})
    target_link_libraries(entry PUBLIC ruffle_engine)

    # hvigor packages whatever CMake emits, so mirror the prebuilt next to
    # libentry.so or the loader will not find it at runtime.
    add_custom_command(TARGET entry POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${RUFFLE_ENGINE_LIB}
            $<TARGET_FILE_DIR:entry>/libruffle_ohos_engine.so)
else()
    message(FATAL_ERROR
        "libruffle_ohos_engine.so not found at ${RUFFLE_ENGINE_LIB}; "
        "run ruffle-master/ohos/build-engine.sh first")
endif()
