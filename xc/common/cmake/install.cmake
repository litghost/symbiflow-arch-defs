function(DEFINE_XC_TOOLCHAIN_TARGET)
  set(options)
  set(oneValueArgs ARCH CONV_SCRIPT SYNTH_SCRIPT ROUTE_CHAN_WIDTH)
  set(multiValueArgs VPR_ARCH_ARGS)

  cmake_parse_arguments(
    DEFINE_XC_TOOLCHAIN_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    "${ARGN}"
  )

  get_target_property_required(VPR env VPR)
  get_target_property_required(GENFASM env GENFASM)

  set(ARCH ${DEFINE_XC_TOOLCHAIN_TARGET_ARCH})
  set(VPR_ARCH_ARGS ${DEFINE_XC_TOOLCHAIN_TARGET_VPR_ARCH_ARGS})
  set(ROUTE_CHAN_WIDTH ${DEFINE_XC_TOOLCHAIN_TARGET_ROUTE_CHAN_WIDTH})
  list(JOIN VPR_BASE_ARGS " " VPR_BASE_ARGS)
  string(JOIN " " VPR_ARGS ${VPR_BASE_ARGS} "--route_chan_width ${ROUTE_CHAN_WIDTH}" ${VPR_ARCH_ARGS})
  get_target_property_required(FAMILY ${ARCH} FAMILY)
  get_target_property_required(DOC_PRJ ${ARCH} DOC_PRJ)
  get_target_property_required(DOC_PRJ_DB ${ARCH} DOC_PRJ_DB)

  set(WRAPPERS
    env
    symbiflow_generate_constraints
    symbiflow_pack
    symbiflow_place
    symbiflow_route
    symbiflow_synth
    symbiflow_write_bitstream
    symbiflow_write_fasm)
  set(TOOLCHAIN_WRAPPERS)

  foreach(WRAPPER ${WRAPPERS})
    set(WRAPPER_PATH "${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/toolchain_wrappers/${WRAPPER}")
    list(APPEND TOOLCHAIN_WRAPPERS ${WRAPPER_PATH})
  endforeach()

  set(VPR_COMMON_TEMPLATE "${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/toolchain_wrappers/vpr_common")
  set(VPR_COMMON "${CMAKE_CURRENT_BINARY_DIR}/vpr_common")
  configure_file(${VPR_COMMON_TEMPLATE} "${VPR_COMMON}" @ONLY)

  install(FILES ${TOOLCHAIN_WRAPPERS} ${VPR_COMMON}
          DESTINATION bin
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  # install python scripts
  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/split_inouts.py
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

        install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_ioplace.py
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

        install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_place_constraints.py
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/vpr_io_place.py
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/vpr_place_constraints.py
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/eblif.py
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  install(FILES ${symbiflow-arch-defs_SOURCE_DIR}/utils/lib/parse_pcf.py
          DESTINATION bin/python/lib)


  # install prjxray techmap
  install(DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/techmap
          DESTINATION share/symbiflow/techmaps/${FAMILY}_vpr)

  # install Yosys scripts
  install(FILES  ${DEFINE_XC_TOOLCHAIN_TARGET_CONV_SCRIPT} ${DEFINE_XC_TOOLCHAIN_TARGET_SYNTH_SCRIPT}
    DESTINATION share/symbiflow/scripts/${FAMILY})

endfunction()

function(DEFINE_XC_PINMAP_CSV_INSTALL_TARGET)
  set(options)
  set(oneValueArgs PART DEVICE_TYPE BOARD DEVICE PACKAGE)
  set(multiValueArgs)

  cmake_parse_arguments(
    DEFINE_XC_PINMAP_CSV_INSTALL_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    "${ARGN}"
  )

  set(PART ${DEFINE_XC_PINMAP_CSV_INSTALL_TARGET_PART})
  set(BOARD ${DEFINE_XC_PINMAP_CSV_INSTALL_TARGET_BOARD})
  set(DEVICE ${DEFINE_XC_PINMAP_CSV_INSTALL_TARGET_DEVICE})
  set(DEVICE_TYPE ${DEFINE_XC_PINMAP_CSV_INSTALL_TARGET_DEVICE_TYPE})
  set(PACKAGE ${DEFINE_XC_PINMAP_CSV_INSTALL_TARGET_PACKAGE})

  get_target_property(USE_ROI ${DEVICE_TYPE} USE_ROI)
  if(USE_ROI OR USE_ROI STREQUAL "USE_ROI-NOTFOUND")
    message(STATUS "Skipping pinmap installation for ${DEVICE}-${PACKAGE} part: ${PART}")
    return()
  endif()

  get_target_property(LIMIT_GRAPH_TO_DEVICE ${DEVICE_TYPE} LIMIT_GRAPH_TO_DEVICE)
  if(LIMIT_GRAPH_TO_DEVICE OR LIMIT_GRAPH_TO_DEVICE STREQUAL "LIMIT_GRAPH_TO_DEVICE-NOTFOUND")
    message(STATUS "Graph limited to a sub-area of the device. Skipping files installation for ${DEVICE}-${PACKAGE} type: ${DEVICE_TYPE}")
    return()
  endif()

  # FIXME: do not install a200t
  if(${DEVICE} STREQUAL "xc7a200t")
    message(STATUS "FIXME: Skipping pinmap installation for ${DEVICE}-${PACKAGE} part: ${PART}")
    return()
  endif()

  get_target_property_required(PINMAP ${BOARD} PINMAP)
  get_file_location(PINMAP_FILE ${PINMAP})
  get_filename_component(PINMAP_FILE_NAME ${PINMAP_FILE} NAME)
  append_file_dependency(DEPS ${PINMAP})
  add_custom_target(
    "PINMAP_INSTALL_${BOARD}_${DEVICE}_${PACKAGE}_${PINMAP_FILE_NAME}"
    ALL
    DEPENDS ${DEPS}
    )
  install(FILES ${PINMAP_FILE}
    DESTINATION "share/symbiflow/arch/${DEVICE}_${PACKAGE}/${PART}"
    RENAME "pinmap.csv")
endfunction()
