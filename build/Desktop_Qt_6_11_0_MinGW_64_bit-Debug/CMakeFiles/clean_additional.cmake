# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles\\appgreatestgame_autogen.dir\\AutogenUsed.txt"
  "CMakeFiles\\appgreatestgame_autogen.dir\\ParseCache.txt"
  "appgreatestgame_autogen"
  )
endif()
