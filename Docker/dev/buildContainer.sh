#!/bin/bash

#docker build -f ./Dockerfile -t scheduling_graph_analysis_dev:1.0 --no-cache ../..
docker build -f ./Dockerfile -t scheduling_graph_analysis_depsonly:1.0 ../..