Import("env")

# This runs once per environment before the build starts.
# It points PlatformIO at <env_name>/src, <env_name>/include, <env_name>/lib
# instead of the default project-root src/include/lib folders.
#
# Because the environment names (esp32cam, esp8266) already match the
# folder names, no per-environment editing is needed here - it's automatic.

env_name = env["PIOENV"]  # e.g. "esp32cam" or "esp8266"
project_dir = env.subst("$PROJECT_DIR")

env.Replace(PROJECT_SRC_DIR=project_dir + "/" + env_name + "/src")
env.Replace(PROJECT_INCLUDE_DIR=project_dir + "/" + env_name + "/include")
env.Replace(PROJECT_LIB_DIR=project_dir + "/" + env_name + "/lib")