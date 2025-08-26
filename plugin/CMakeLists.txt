cmake_minimum_required(VERSION 3.19)
project(Caelestia VERSION "0.0.1")

set(QT_MIN_VERSION "6.9.0")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_compile_options(-Wall -Wextra)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)

if(QT_KNOWN_POLICY_QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()

set(INSTALL_QMLDIR "" CACHE STRING "QML install dir")
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")
qt_standard_project_setup()
add_subdirectory(src/Caelestia)
