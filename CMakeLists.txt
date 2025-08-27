cmake_minimum_required(VERSION 3.19)
project(caelestia-shell VERSION "0.0.1")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(INSTALL_LIBDIR "/usr/lib/caelestia" CACHE STRING "Library install dir")
set(INSTALL_QMLDIR "/usr/lib/qt6/qml" CACHE STRING "QML install dir")
set(INSTALL_QSCONFDIR "/etc/xdg/quickshell/caelestia" CACHE STRING "Quickshell config install dir")

add_compile_options(-Wall -Wextra)

add_subdirectory(assets/cpp)
add_subdirectory(plugin)

foreach(dir assets components config modules services utils)
    install(DIRECTORY ${dir} DESTINATION "${INSTALL_QSCONFDIR}")
endforeach()
install(FILES shell.qml LICENSE DESTINATION "${INSTALL_QSCONFDIR}")
