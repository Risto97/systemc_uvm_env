function(verilate_rtl OUT_LIB RTL_LIB)
    get_target_property(V_SOURCES ${RTL_LIB} INTERFACE_V_SOURCES)
    get_target_property(VLT_CFG_FILES ${RTL_LIB} VERILATOR_CFG_FILES)
    get_target_property(VLT_ARGS ${RTL_LIB} VERILATOR_ARGS)
    get_target_property(V_DEFS ${RTL_LIB} VERILOG_DEFS)

    if(VLT_ARGS STREQUAL "VLT_ARGS-NOTFOUND")
        set(VLT_ARGS "")
    endif()

    if(VLT_CFG_FILES STREQUAL "VLT_CFG_FILES-NOTFOUND")
        set(VLT_CFG_FILES "")
    endif()

    if(V_DEFS STREQUAL "V_DEFS-NOTFOUND")
        set(V_DEFS "")
    else()
        foreach(def ${V_DEFS})
            list(APPEND VLT_DEFS -D${def})
        endforeach()
    endif()

    set(TAG OPEN)
    find_file(libs_conf_cmake "libs_conf.cmake"
        PATHS "$ENV{SC_UVM_ENV_HOME}/open" NO_DEFAULT_PATH
        NO_CACHE
        )
    include(${libs_conf_cmake})

    find_library(systemc_lib_sci systemc
        PATHS "${SYSTEMC_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )


    set(VERILATOR_ROOT ${VERILATOR_HOME_${TAG}})
    find_package(verilator HINTS ${VERILATOR_ROOT})
    if (NOT verilator_FOUND)
      message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
    endif()

# SystemC dependencies
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)

    list(GET V_SOURCES 0 TOP_V_FILE)
    get_filename_component(V_SOURCE_WO_EXT ${TOP_V_FILE} NAME_WE)

    # get_target_property(VERILATOR_ARGS ${RTL_LIB} VERILATOR_ARGS)
    add_library(${OUT_LIB} EXCLUDE_FROM_ALL)
    verilate(${OUT_LIB} SYSTEMC
        SOURCES ${V_SOURCES} ${VLT_CFG_FILES}
        PREFIX ${V_SOURCE_WO_EXT}
        VERILATOR_ARGS --pins-sc-uint --trace --trace-structs -Wno-fatal ${VLT_ARGS} ${VLT_DEFS}
            )

        target_include_directories(${OUT_LIB} PRIVATE "${SYSTEMC_HOME_${TAG}}/include")
        target_link_libraries(${OUT_LIB} PRIVATE ${systemc_lib})
        target_link_options(${OUT_LIB} PRIVATE -pthread)

endfunction()

function(verilate_tb SC_LIB RTL_LIBS)

    find_file(libs_conf_cmake "libs_conf.cmake"
        PATHS "$ENV{SC_UVM_ENV_HOME}/open" NO_DEFAULT_PATH
        NO_CACHE
        )
    include(${libs_conf_cmake})

    find_file(crave_conf_cmake "crave_conf.cmake"
        PATHS "$ENV{SC_UVM_ENV_HOME}/open/crave" NO_DEFAULT_PATH
        NO_CACHE
        )
    include(${crave_conf_cmake})

    set(TAG OPEN)
    find_library(uvc_lib uvc
        PATHS "${UVC_HOME_${TAG}}/*"
        NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(systemc_lib_sci systemc
        PATHS "${SYSTEMC_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(sc_uvm_lib uvm-systemc
        PATHS "${SYSTEMC_UVM_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(scv_lib scv
        PATHS "${SCV_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(crave_lib crave
        PATHS "${CRAVE_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(z3_lib z3
        PATHS "${Z3_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(cudd_lib cudd
        PATHS "${CUDD_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(metaSMT_lib metaSMT
        PATHS "${CRAVE_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(boost_system boost_system
        PATHS "${BOOST_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )
    find_library(boost_fs boost_filesystem
        PATHS "${BOOST_HOME_${TAG}}/*" NO_DEFAULT_PATH
        NO_CACHE
        )

    list(APPEND EXTRA_LIBS          # order is important
                ${uvc_lib}
                ${crave_lib}
                # ${scv_lib}
                ${sc_uvm_lib}
                ${systemc_lib_sci}
                ${metaSMT_lib}
                ${z3_lib}
                ${cudd_lib}
                ${boost_fs}
                ${boost_system}
                -fopenmp
                )

    list(APPEND EXTRA_INCLUDES 
        "${SYSTEMC_HOME_${TAG}}/include"
        "${SYSTEMC_UVM_HOME_${TAG}}/include"
        "${SCV_HOME_${TAG}}/include"
        "${FC4SC_HOME_${TAG}}/includes"
        "${SCT_HOME_${TAG}}/components/common/sctcommon/"
        "${CRAVE_HOME_${TAG}}/include" 

        "${UVC_HOME_${TAG}}/include" 
        )

    get_target_property(ENV_SOURCES ${SC_LIB} INTERFACE_SOURCES)
    get_target_property(ENV_INC_DIR ${SC_LIB} INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(ENV_COMP_OPT ${SC_LIB} INTERFACE_COMPILE_OPTIONS)

    add_executable(verilator_tb EXCLUDE_FROM_ALL
        ${ENV_SOURCES}
        )
    add_dependencies(verilator_tb ${SC_LIB})

    target_compile_options(verilator_tb PRIVATE
                        -DVERILATOR=1
                        ${ENV_COMP_OPT}
                        )
    target_link_options(verilator_tb PRIVATE -pthread)

    target_include_directories(verilator_tb PRIVATE
                               ${ENV_INC_DIR}
                               ${EXTRA_INCLUDES}
                               )

    target_link_libraries(verilator_tb PRIVATE
                          ${RTL_LIBS} 
                          ${EXTRA_LIBS}
                        )

    if(DEFINED ENV{LD_LIBRARY_PATH})
        set(RUN_PATH "LD_LIBRARY_PATH=${GLIB_DIR}:$ENV{LD_LIBRARY_PATH}")
    else()
        set(RUN_PATH "LD_LIBRARY_PATH=${GLIB_DIR}")
    endif()

    get_target_property(RUN_ARGS ${PROJECT_NAME} RUN_ARGS)
    if(RUN_ARGS STREQUAL "RUN_ARGS-NOTFOUND")
        set(RUN_ARGS "")
    endif()

    add_custom_target(run
        ${COMMAND} 
        ${CMAKE_COMMAND} -E env ${RUN_PATH}
            ./verilator_tb ${RUN_ARGS}
        DEPENDS verilator_tb)
               
endfunction()
