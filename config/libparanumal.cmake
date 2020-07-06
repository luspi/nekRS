include(FetchContent)
set(FETCHCONTENT_QUIET OFF)

# TODO: Need to get value from OCCA?
set(USE_OCCA_MEM_BYTE_ALIGN 64)
add_definitions(-DUSE_OCCA_MEM_BYTE_ALIGN=${USE_OCCA_MEM_BYTE_ALIGN})

# ---------------------------------------------------------
# Download dependencies
# ---------------------------------------------------------

# libparanumal
# ------------

set(LIBP_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/3rd_party/libparanumal)

# If LIBP is not in source tree, download it in build directory
if (EXISTS ${LIBP_SOURCE_DIR})
  message(STATUS "Using libparanumal source in ${LIBP_SOURCE_DIR}")
else()
  FetchContent_Declare(
      libp_content
      GIT_REPOSITORY https://gitlab.com/nekrs/libparanumal.git
      GIT_TAG next)
  FetchContent_GetProperties(libp_content)
  if(NOT libp_content_POPULATED)
    FetchContent_Populate(libp_content)
    FetchContent_GetProperties(libp_content)
  endif()
  set(LIBP_SOURCE_DIR ${libp_content_SOURCE_DIR})
endif()

set(OGS_SOURCE_DIR ${LIBP_SOURCE_DIR}/libs/gatherScatter)
set(PARALMOND_SOURCE_DIR ${LIBP_SOURCE_DIR}/libs/parAlmond)
set(ELLIPTIC_SOURCE_DIR ${LIBP_SOURCE_DIR}/solvers/elliptic)

# HYPRE
# ------------

set(HYPRE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/3rd_party/hypre)
# * These two variables are significant to HYPRE's CMakeLists, not our own
#   HYPRE's CMakeLists leak some variables into parent project, and this is a workaround
set(HYPRE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX} CACHE PATH "" FORCE)
set(HYPRE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "" FORCE)

if (EXISTS ${HYPRE_SOURCE_DIR})
  message(STATUS "Using HYPRE source in ${HYPRE_SOURCE_DIR}")
  add_subdirectory(${HYPRE_SOURCE_DIR}/src)
  get_property(HYPRE_BINARY_DIR TARGET HYPRE PROPERTY BINARY_DIR)
else()

  FetchContent_Declare(
    hypre_content
    URL https://github.com/hypre-space/hypre/archive/v2.18.2.tar.gz )
  FetchContent_GetProperties(hypre_content)
  if (NOT hypre_content_POPULATED)
    FetchContent_Populate(hypre_content)
    FetchContent_GetProperties(hypre_content)
  endif()
  set(HYPRE_SOURCE_DIR ${hypre_content_SOURCE_DIR})
  set(HYPRE_BINARY_DIR ${hypre_content_BINARY_DIR})

  # * Exclude from all since HYPRE CMakeLists adds a bunch of targets we don't need
  #   libHYPRE will be build just fine, since we've explicitly declared it as a dependency
  add_subdirectory(${HYPRE_SOURCE_DIR}/src ${HYPRE_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# ---------------------------------------------------------
# libogs
# ---------------------------------------------------------

set(OGS_SOURCES
        ${OGS_SOURCE_DIR}/src/ogsGather.cpp
        ${OGS_SOURCE_DIR}/src/ogsGatherMany.cpp
        ${OGS_SOURCE_DIR}/src/ogsGatherScatter.cpp
        ${OGS_SOURCE_DIR}/src/ogsGatherScatterMany.cpp
        ${OGS_SOURCE_DIR}/src/ogsGatherScatterVec.cpp
        ${OGS_SOURCE_DIR}/src/ogsGatherVec.cpp
        ${OGS_SOURCE_DIR}/src/ogsHostGather.c
        ${OGS_SOURCE_DIR}/src/ogsHostGatherMany.c
        ${OGS_SOURCE_DIR}/src/ogsHostGatherScatter.c
        ${OGS_SOURCE_DIR}/src/ogsHostGatherScatterMany.c
        ${OGS_SOURCE_DIR}/src/ogsHostGatherScatterVec.c
        ${OGS_SOURCE_DIR}/src/ogsHostGatherVec.c
        ${OGS_SOURCE_DIR}/src/ogsHostScatter.c
        ${OGS_SOURCE_DIR}/src/ogsHostScatterMany.c
        ${OGS_SOURCE_DIR}/src/ogsHostScatterVec.c
        ${OGS_SOURCE_DIR}/src/ogsHostSetup.c
        ${OGS_SOURCE_DIR}/src/ogsKernels.cpp
        ${OGS_SOURCE_DIR}/src/ogsMappedAlloc.cpp
        ${OGS_SOURCE_DIR}/src/ogsScatter.cpp
        ${OGS_SOURCE_DIR}/src/ogsScatterMany.cpp
        ${OGS_SOURCE_DIR}/src/ogsScatterVec.cpp
        ${OGS_SOURCE_DIR}/src/ogsSetup.cpp)

add_library(libogs ${OGS_SOURCES})
set_target_properties(libogs PROPERTIES OUTPUT_NAME ogs)
target_compile_definitions(libogs PUBLIC -DDOGS="${CMAKE_INSTALL_PREFIX}/gatherScatter")
target_include_directories(libogs PUBLIC
        ${OGS_SOURCE_DIR}/include
        ${OGS_SOURCE_DIR}
        ${LIBP_SOURCE_DIR}/include)
target_link_libraries(libogs PUBLIC libocca gs)

# ---------------------------------------------------------
# libparanumal
# ---------------------------------------------------------

set(LIBP_SOURCES
        src/core/occaDeviceConfig.cpp
        ${LIBP_SOURCE_DIR}/src/hash.c
        ${LIBP_SOURCE_DIR}/src/matrixConditionNumber.c
        ${LIBP_SOURCE_DIR}/src/matrixInverse.c
        ${LIBP_SOURCE_DIR}/src/meshApplyElementMatrix.c
        ${LIBP_SOURCE_DIR}/src/meshConnect.c
        ${LIBP_SOURCE_DIR}/src/meshConnectBoundary.c
        ${LIBP_SOURCE_DIR}/src/meshConnectFaceNodes2D.c
        ${LIBP_SOURCE_DIR}/src/meshConnectFaceNodes3D.c
        ${LIBP_SOURCE_DIR}/src/meshConnectPeriodicFaceNodes2D.c
        ${LIBP_SOURCE_DIR}/src/meshConnectPeriodicFaceNodes3D.c
        ${LIBP_SOURCE_DIR}/src/meshGeometricFactorsHex3D.c
        ${LIBP_SOURCE_DIR}/src/meshGeometricFactorsQuad2D.c
        ${LIBP_SOURCE_DIR}/src/meshGeometricFactorsQuad3D.c
        ${LIBP_SOURCE_DIR}/src/meshGeometricFactorsTet3D.c
        ${LIBP_SOURCE_DIR}/src/meshGeometricFactorsTri2D.c
        ${LIBP_SOURCE_DIR}/src/meshGeometricFactorsTri3D.c
        ${LIBP_SOURCE_DIR}/src/meshGeometricPartition2D.c
        ${LIBP_SOURCE_DIR}/src/meshGeometricPartition3D.c
        ${LIBP_SOURCE_DIR}/src/meshHaloExchange.c
        ${LIBP_SOURCE_DIR}/src/meshHaloExtract.c
        ${LIBP_SOURCE_DIR}/src/meshHaloSetup.c
        ${LIBP_SOURCE_DIR}/src/meshLoadReferenceNodesHex3D.c
        ${LIBP_SOURCE_DIR}/src/meshLoadReferenceNodesQuad2D.c
        ${LIBP_SOURCE_DIR}/src/meshLoadReferenceNodesTet3D.c
        ${LIBP_SOURCE_DIR}/src/meshLoadReferenceNodesTri2D.c
        ${LIBP_SOURCE_DIR}/src/meshOccaSetup2D.c
        ${LIBP_SOURCE_DIR}/src/meshOccaSetup3D.c
        ${LIBP_SOURCE_DIR}/src/meshOccaSetupQuad3D.c
        ${LIBP_SOURCE_DIR}/src/meshParallelConnectNodes.c
        ${LIBP_SOURCE_DIR}/src/meshParallelConnectOpt.c
        ${LIBP_SOURCE_DIR}/src/meshParallelConsecutiveGlobalNumbering.c
        ${LIBP_SOURCE_DIR}/src/meshParallelGatherScatterSetup.c
        ${LIBP_SOURCE_DIR}/src/meshParallelReaderHex3D.c
        ${LIBP_SOURCE_DIR}/src/meshParallelReaderQuad2D.c
        ${LIBP_SOURCE_DIR}/src/meshParallelReaderQuad3D.c
        ${LIBP_SOURCE_DIR}/src/meshParallelReaderTet3D.c
        ${LIBP_SOURCE_DIR}/src/meshParallelReaderTri2D.c
        ${LIBP_SOURCE_DIR}/src/meshParallelReaderTri3D.c
        ${LIBP_SOURCE_DIR}/src/meshPartitionStatistics.c
        ${LIBP_SOURCE_DIR}/src/meshPhysicalNodesQuad2D.c
        ${LIBP_SOURCE_DIR}/src/meshPhysicalNodesQuad3D.c
        ${LIBP_SOURCE_DIR}/src/meshPhysicalNodesTet3D.c
        ${LIBP_SOURCE_DIR}/src/meshPhysicalNodesTri2D.c
        ${LIBP_SOURCE_DIR}/src/meshPhysicalNodesTri3D.c
        ${LIBP_SOURCE_DIR}/src/meshPlotVTU2D.c
        ${LIBP_SOURCE_DIR}/src/meshPlotVTU3D.c
        ${LIBP_SOURCE_DIR}/src/meshPrint2D.c
        ${LIBP_SOURCE_DIR}/src/meshPrint3D.c
        ${LIBP_SOURCE_DIR}/src/meshSetup.c
        ${LIBP_SOURCE_DIR}/src/meshSetupBoxHex3D.c
        ${LIBP_SOURCE_DIR}/src/meshSetupBoxQuad2D.c
        ${LIBP_SOURCE_DIR}/src/meshSetupHex3D.c
        ${LIBP_SOURCE_DIR}/src/meshSetupQuad2D.c
        ${LIBP_SOURCE_DIR}/src/meshSetupQuad3D.c
        ${LIBP_SOURCE_DIR}/src/meshSetupTet3D.c
        ${LIBP_SOURCE_DIR}/src/meshSetupTri2D.c
        ${LIBP_SOURCE_DIR}/src/meshSetupTri3D.c
        ${LIBP_SOURCE_DIR}/src/meshSurfaceGeometricFactorsHex3D.c
        ${LIBP_SOURCE_DIR}/src/meshSurfaceGeometricFactorsQuad2D.c
        ${LIBP_SOURCE_DIR}/src/meshSurfaceGeometricFactorsQuad3D.c
        ${LIBP_SOURCE_DIR}/src/meshSurfaceGeometricFactorsTet3D.c
        ${LIBP_SOURCE_DIR}/src/meshSurfaceGeometricFactorsTri2D.c
        ${LIBP_SOURCE_DIR}/src/meshSurfaceGeometricFactorsTri3D.c
        ${LIBP_SOURCE_DIR}/src/meshVTU2D.c
        ${LIBP_SOURCE_DIR}/src/meshVTU3D.c
        ${LIBP_SOURCE_DIR}/src/mysort.c
        ${LIBP_SOURCE_DIR}/src/occaHostMallocPinned.c
        ${LIBP_SOURCE_DIR}/src/parallelSort.c
        ${LIBP_SOURCE_DIR}/src/readArray.c
        ${LIBP_SOURCE_DIR}/src/setupAide.c
        ${LIBP_SOURCE_DIR}/src/timer.c)

set_source_files_properties(${LIBP_SOURCES} PROPERTIES LANGUAGE CXX)
add_library(libP ${LIBP_SOURCES})
set_target_properties(libP PROPERTIES OUTPUT_NAME P)
target_compile_definitions(libP PUBLIC -DDHOLMES="${CMAKE_INSTALL_PREFIX}/libparanumal")
target_include_directories(libP PUBLIC ${LIBP_SOURCE_DIR}/include src/core/)
target_link_libraries(libP PUBLIC libogs libocca blasLapack)

# ---------------------------------------------------------
# libparAlmond
# ---------------------------------------------------------

set(PARALMOND_SOURCES
        ${PARALMOND_SOURCE_DIR}/hypre/hypre.c
        ${PARALMOND_SOURCE_DIR}/src/SpMV.cpp
        ${PARALMOND_SOURCE_DIR}/src/agmgLevel.cpp
        ${PARALMOND_SOURCE_DIR}/src/agmgSetup/agmgSetup.cpp
        ${PARALMOND_SOURCE_DIR}/src/agmgSetup/constructProlongation.cpp
        ${PARALMOND_SOURCE_DIR}/src/agmgSetup/formAggregates.cpp
        ${PARALMOND_SOURCE_DIR}/src/agmgSetup/galerkinProd.cpp
        ${PARALMOND_SOURCE_DIR}/src/agmgSetup/strongGraph.cpp
        ${PARALMOND_SOURCE_DIR}/src/agmgSetup/transpose.cpp
        ${PARALMOND_SOURCE_DIR}/src/agmgSmoother.cpp
        ${PARALMOND_SOURCE_DIR}/src/coarseSolver.cpp
        ${PARALMOND_SOURCE_DIR}/src/kernels.cpp
        ${PARALMOND_SOURCE_DIR}/src/level.cpp
        ${PARALMOND_SOURCE_DIR}/src/matrix.cpp
        ${PARALMOND_SOURCE_DIR}/src/multigrid.cpp
        ${PARALMOND_SOURCE_DIR}/src/parAlmond.cpp
        ${PARALMOND_SOURCE_DIR}/src/pcg.cpp
        ${PARALMOND_SOURCE_DIR}/src/pgmres.cpp
        ${PARALMOND_SOURCE_DIR}/src/solver.cpp
        ${PARALMOND_SOURCE_DIR}/src/utils.cpp
        ${PARALMOND_SOURCE_DIR}/src/vector.cpp)

add_library(libparAlmond ${PARALMOND_SOURCES})
set_target_properties(libparAlmond PROPERTIES OUTPUT_NAME parAlmond)
target_compile_definitions(libparAlmond PUBLIC -DDPARALMOND="${CMAKE_INSTALL_PREFIX}/parAlmond" PRIVATE -DHYPRE)
target_include_directories(libparAlmond 
        PUBLIC
        ${PARALMOND_SOURCE_DIR}/include
        ${PARALMOND_SOURCE_DIR}
        ${PARALMOND_SOURCE_DIR}/hypre
        ${LIBP_SOURCE_DIR}/include
        PRIVATE
        ${HYPRE_SOURCE_DIR}/src
        ${HYPRE_SOURCE_DIR}/src/utilities
        ${HYPRE_SOURCE_DIR}/src/seq_mv
        ${HYPRE_SOURCE_DIR}/src/parcsr_mv
        ${HYPRE_SOURCE_DIR}/src/parcsr_ls
        ${HYPRE_SOURCE_DIR}/src/IJ_mv
        ${HYPRE_SOURCE_DIR}/src/multivector
        ${HYPRE_SOURCE_DIR}/src/krylov
        ${HYPRE_BINARY_DIR})
target_link_libraries(libparAlmond PUBLIC libogs libocca PRIVATE HYPRE)
# This conflicts with the stdlib "version" header...
file(REMOVE ${HYPRE_SOURCE_DIR}/src/utilities/version)

# ---------------------------------------------------------
# libelliptic
# ---------------------------------------------------------

set(ELLIPTIC_SOURCES
        ${ELLIPTIC_SOURCE_DIR}/src/NBFPCG.c
        ${ELLIPTIC_SOURCE_DIR}/src/NBPCG.c
        ${ELLIPTIC_SOURCE_DIR}/src/PCG.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticBuildContinuous.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticBuildContinuousGalerkin.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticBuildIpdg.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticBuildJacobi.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticBuildLocalPatches.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticBuildMultigridLevel.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticHaloExchange.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticKernelInfo.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticMixedCopy.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticMultiGridLevel.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticMultiGridLevelSetup.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticMultiGridSetup.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticOperator.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticPlotVTUHex3D.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticPreconditioner.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticPreconditionerSetup.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticSEMFEMSetup.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticScaledAdd.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticSetScalar.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticSolve.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticSolveSetup.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticThinOas.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticThinOasSetup.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticUpdateNBFPCG.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticUpdateNBPCG.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticUpdatePCG.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticVectors.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticWeightedInnerProduct.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticWeightedNorm2.c
        ${ELLIPTIC_SOURCE_DIR}/src/ellipticZeroMean.c)

set_source_files_properties(${ELLIPTIC_SOURCES} PROPERTIES LANGUAGE CXX)
add_library(libelliptic ${ELLIPTIC_SOURCES})
set_target_properties(libelliptic PROPERTIES OUTPUT_NAME elliptic)
target_compile_definitions(libelliptic PUBLIC -DDELLIPTIC="${CMAKE_INSTALL_PREFIX}/elliptic")
target_include_directories(libelliptic PUBLIC ${ELLIPTIC_SOURCE_DIR})
target_link_libraries(libelliptic PUBLIC libP libparAlmond libogs libocca blasLapack)

# ---------------------------------------------------------
# install
# ---------------------------------------------------------

set(file_pattern "\.okl$|\.c$|\.hpp$|\.tpp$|\.h$|hex.*\.dat$")

install(TARGETS libP LIBRARY DESTINATION libparanumal)
install(DIRECTORY 
  ${LIBP_SOURCE_DIR}/include 
  ${LIBP_SOURCE_DIR}/nodes
  ${LIBP_SOURCE_DIR}/okl 
  DESTINATION libparanumal
  FILES_MATCHING REGEX ${file_pattern})

install(TARGETS libogs LIBRARY DESTINATION gatherScatter)
install(DIRECTORY
  ${OGS_SOURCE_DIR}/include 
  ${OGS_SOURCE_DIR}/okl 
  DESTINATION gatherScatter
  FILES_MATCHING REGEX ${file_pattern})
install(FILES ${OGS_SOURCE_DIR}/ogs.hpp DESTINATION gatherScatter)

install(TARGETS libparAlmond LIBRARY DESTINATION parAlmond)
install(DIRECTORY
  ${PARALMOND_SOURCE_DIR}/include
  ${PARALMOND_SOURCE_DIR}/okl
  DESTINATION parAlmond
  FILES_MATCHING REGEX ${file_pattern})
install(FILES ${PARALMOND_SOURCE_DIR}/parAlmond.hpp DESTINATION gatherScatter)

install(TARGETS libelliptic LIBRARY DESTINATION elliptic)
install(DIRECTORY
  ${ELLIPTIC_SOURCE_DIR}/data
  ${ELLIPTIC_SOURCE_DIR}/okl
  DESTINATION elliptic
  FILES_MATCHING REGEX ${file_pattern})
install(FILES 
  ${ELLIPTIC_SOURCE_DIR}/elliptic.h
  ${ELLIPTIC_SOURCE_DIR}/ellipticMultiGrid.h
  ${ELLIPTIC_SOURCE_DIR}/ellipticPrecon.h
  DESTINATION gatherScatter)