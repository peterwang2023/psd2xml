option(enable_pch "Enable precompiled headers" OFF)

function(add_precompiled_header target header src) # in_tree
    if(enable_pch)
        set(pch_abs "${CMAKE_CURRENT_SOURCE_DIR}/${header}")
        if(MSVC)
            set(pch_out "${CMAKE_CURRENT_BINARY_DIR}/${target}.pch")
            get_filename_component(pch_basename ${header} NAME_WE)
            set_target_properties(${target} PROPERTIES COMPILE_FLAGS "/Yu\"${header}\" /Fp\"${pch_out}\"")
            set_source_files_properties(${src} PROPERTIES COMPILE_FLAGS "/Yc\"${header}\" /Fp\"${pch_out}\"")
        elseif(CMAKE_COMPILER_IS_GNUCC)
            if(ARGV3)
                set(pch_out "${pch_abs}.gch")
                message("** Precompiled header for ${target} (in tree):\n   ${pch_out}")
            else()
                set(pch_out_basename "${CMAKE_CURRENT_BINARY_DIR}/${target}.h")
                set(pch_out "${pch_out_basename}.gch")
                message("** Precompiled header for ${target} (out of tree):\n   ${pch_out}")
            endif()

            if(src MATCHES "\\.(cpp|cc|cxx)$")
                set(lang CXX)
                set(opt_x c++-header)
                set(suffix cpp)
            else()
                set(lang C)
                set(opt_x c-header)
                set(suffix c)
            endif()

            set(cppflags ${CMAKE_${lang}_FLAGS})
            if(CMAKE_BUILD_TYPE)
                string(TOUPPER "CMAKE_${lang}_FLAGS_${CMAKE_BUILD_TYPE}" flags_var_name)
                list(APPEND cppflags ${${flags_var_name}})
            endif()
            get_directory_property(include_dirs INCLUDE_DIRECTORIES)
            foreach(item ${include_dirs})
                list(APPEND cppflags "-I${item}")
            endforeach(item)
            get_directory_property(macros DIRECTORY ${CMAKE_SOURCE_DIR} DEFINITIONS)
            list(APPEND cppflags ${macros})
            get_directory_property(macros DEFINITIONS)
            list(APPEND cppflags ${macros})
            separate_arguments(cppflags)

            add_custom_command(
                OUTPUT "${pch_out}"
                COMMAND ${CMAKE_${lang}_COMPILER} -x ${opt_x} ${cppflags} -o ${pch_out} ${src}
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                IMPLICIT_DEPENDS ${lang} ${header}
                VERBATIM
            )
            add_custom_target(${target}_pch DEPENDS "${pch_out}")
            add_dependencies(${target} ${target}_pch)

            if(pch_out_basename)
                get_target_property(cflags ${target} COMPILE_FLAGS)
                if(cflags STREQUAL "cflags-NOTFOUND")
                    set(cflags "")
                endif()
                set_target_properties(${target} PROPERTIES COMPILE_FLAGS "${cflags} -include \"${pch_out_basename}\"")
            endif()
        endif()
    endif()
endfunction()
