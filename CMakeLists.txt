##############################################################################
# CMake
##############################################################################

cmake_minimum_required(VERSION 2.8.3)
project(report_card)

##############################################################################
# Catkin
##############################################################################

find_package(catkin REQUIRED rosjava_build_tools knowrob_cram knowrob_mongo)

catkin_rosjava_setup(installApp publishMavenJavaPublicationToMavenRepository writeClasspath)

catkin_package(
  DEPENDS knowrob_mongo knowrob_cram
)

##############################################################################
# Installation
##############################################################################

# Change this to match the maven group name you have specified in the 
# allprojects closure the root build.gradle
install(DIRECTORY ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_MAVEN_DESTINATION}/org/knowrob/${PROJECT_NAME}/ 
        DESTINATION ${CATKIN_GLOBAL_MAVEN_DESTINATION}/org/knowrob/${PROJECT_NAME})

        