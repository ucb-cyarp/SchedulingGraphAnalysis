# PyCharm Docker Dev

PyCharm provides a way to set the project to be run in a docker container.  
This is particularly helpful here because a full graphviz-dev install is required.

Fortunately, local docker container images can be used which allows us to supply our own docker file
with the dependencies met

# Config
1. Build the dependencies docker container by executing `buildContainer.sh`
2. Follow the instructions from [JetBrains](https://www.jetbrains.com/help/pycharm/using-docker-as-a-remote-interpreter.html#run)
    1. Select `scheduling_graph_analysis_depsonly:1.0` as the base image name 
    2. Select `python3` as the python path
3. Pres the run button and check that a new docker container is created and then deleted