cmake_minimum_required(VERSION 3.14)
project(nexus_backend CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Drogon CONFIG REQUIRED)

set(NEXUS_SOURCES
    src/main.cpp
    src/db/database.cpp
    src/repositories/catalog_repository.cpp
    src/routes/route_registry.cpp
    src/routes/swagger_routes.cpp
    src/utils/openapi_generator.cpp
    src/services/auth_service.cpp
    src/services/catalog_service.cpp
    src/services/order_service.cpp
)

add_executable(nexus_server ${NEXUS_SOURCES})

target_include_directories(nexus_server PRIVATE include)

find_package(OpenSSL REQUIRED)
target_link_libraries(nexus_server PRIVATE Drogon::Drogon OpenSSL::Crypto)

add_custom_command(TARGET nexus_server POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_FILE_DIR:nexus_server>/data
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_SOURCE_DIR}/data/catalog.json
        $<TARGET_FILE_DIR:nexus_server>/data/catalog.json
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_SOURCE_DIR}/openapi.yaml
        $<TARGET_FILE_DIR:nexus_server>/openapi.yaml
)
