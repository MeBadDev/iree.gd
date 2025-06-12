#[=======================================================================[.rst:
Windows
-------
This file contains functions for options and configuration for targeting the
Windows platform
Because this file is included into the top level CMakelists.txt before the
project directive, it means that
* ``CMAKE_CURRENT_SOURCE_DIR`` is the location of godot-cpp's CMakeLists.txt
* ``CMAKE_SOURCE_DIR`` is the location where any prior ``project(...)``
    directive was
MSVC Runtime Selection
----------------------
@@ -19,48 +25,50 @@ Default: ``CMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
This initializes each target's ``MSVC_RUNTIME_LIBRARY`` property at the time of
target creation.
it is stated in the msvc_ documentation that: "All modules passed to a given
invocation of the linker must have been compiled with the same runtime library
compiler option (/MD, /MT, /LD)."
This creates a conundrum for us, the ``CMAKE_MSVC_RUNTIME_LIBRARY`` needs to be
correct at the time the target is created, but we have no control over the
consumers CMake scripts, and the per-target ``MSVC_RUNTIME_LIBRARY`` property
is not transient.
We need ``CMAKE_MSVC_RUNTIME_LIBRARY`` to be ``"$<1:>"`` to ensure it
will not add any flags. And then use ``target_compile_options()`` so that our
flags will propagate to consumers.
It has been raised that not using ``CMAKE_MSVC_RUNTIME_LIBRARY`` can also cause
issues_ when a dependency( independent to godot-cpp ) that doesn't set any
runtime flags, which relies purely on the ``CMAKE_MSVC_RUNTIME_LIBRARY``
variable will very likely not have the correct msvc runtime flags set.
So we'll set ``CMAKE_MSVC_RUNTIME_LIBRARY`` as CACHE STRING so that it will be
available for consumer target definitions, but also be able to be overridden if
needed.
In the interests of playing nicely we detect whether we are being consumed
and notify the consumer that we are setting ``CMAKE_MSVC_RUNTIME_LIBRARY``,
that dependent targets rely on it, and point them to these comments as to why.
Additionally we message consumers notifying them and pointing to this
documentation.
.. _CMP0091:https://cmake.org/cmake/help/latest/policy/CMP0091.html
.. _property:https://cmake.org/cmake/help/latest/variable/CMAKE_MSVC_RUNTIME_LIBRARY.html
.. https://discourse.cmake.org/t/mt-staticrelease-doesnt-match-value-md-dynamicrelease/5428/4
.. _msvc: https://learn.microsoft.com/en-us/cpp/build/reference/md-mt-ld-use-run-time-library
.. _issues: https://github.com/godotengine/godot-cpp/issues/1699
]=======================================================================]
if( PROJECT_NAME ) # we are not the top level if this is true
    if( DEFINED CMAKE_MSVC_RUNTIME_LIBRARY )
        # Warning that we are clobbering the variable.
        message( WARNING "setting CMAKE_MSVC_RUNTIME_LIBRARY to \"$<1:>\"")
    else(  )
        # Notification that we are setting the variable
        message( STATUS "setting CMAKE_MSVC_RUNTIME_LIBRARY to \"$<1:>\"")
    endif()
endif()
set( CMAKE_MSVC_RUNTIME_LIBRARY "$<1:>" CACHE INTERNAL "Select the MSVC runtime library for use by compilers targeting the MSVC ABI." )

#[============================[ Windows Options ]============================]
function( windows_options )

    option( GODOT_USE_STATIC_CPP "Link MinGW/MSVC C++ runtime libraries statically" ON )

    option( GODOT_DEBUG_CRT "Compile with MSVC's debug CRT (/MDd)" OFF )

    message( STATUS "If not already cached, setting CMAKE_MSVC_RUNTIME_LIBRARY.\n"
            "\tFor more information please read godot-cpp/cmake/windows.cmake")

    set( CMAKE_MSVC_RUNTIME_LIBRARY
            "MultiThreaded$<IF:$<BOOL:${GODOT_DEBUG_CRT}>,DebugDLL,$<$<NOT:$<BOOL:${GODOT_USE_STATIC_CPP}>>:DLL>>"
            CACHE STRING "Select the MSVC runtime library for use by compilers targeting the MSVC ABI.")
endfunction()


#[===========================[ Target Generation ]===========================]
function( windows_generate )
    set( STATIC_CPP "$<BOOL:${GODOT_USE_STATIC_CPP}>")
    set( DEBUG_CRT "$<BOOL:${GODOT_DEBUG_CRT}>" )

    set_target_properties( ${TARGET_NAME}
            PROPERTIES
@@ -76,11 +84,6 @@ function( windows_generate )
            >
    )

    target_compile_options( ${TARGET_NAME}
        PUBLIC
            $<${IS_MSVC}:$<IF:${DEBUG_CRT},/MDd,$<IF:${STATIC_CPP},/MT,/MD>>>
    )

    target_link_options( ${TARGET_NAME}
            PUBLIC