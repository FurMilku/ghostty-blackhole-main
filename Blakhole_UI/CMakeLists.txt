cmake_minimum_required(VERSION 3.16)

project(BlakholeUI VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Widgets OpenGL)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appBlakholeUI
    main.cpp
    core/systemtray.h
    core/systemtray.cpp
    core/blackholecore.h
    core/blackholecore.cpp
    core/blackholepreviewfbo.h
    core/blackholepreviewfbo.cpp
)

file(GLOB QML_COMPONENTS CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "components/*.qml")
file(GLOB QML_PAGES CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "pages/*.qml")

qt_add_qml_module(appBlakholeUI
    URI BlakholeUI
    VERSION 1.0
    QML_FILES
        Main.qml
        ${QML_COMPONENTS}
        ${QML_PAGES}
)

qt_add_resources(APP_RESOURCES
    src.qrc
)

target_sources(appBlakholeUI PRIVATE ${APP_RESOURCES})

set_target_properties(appBlakholeUI PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appBlakholeUI
    PRIVATE Qt6::Quick Qt6::Widgets Qt6::OpenGL dwmapi ole32
)

include(GNUInstallDirs)
install(TARGETS appBlakholeUI
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
