FROM ubuntu:18.04

ARG DEBIAN_FRONTEND="noninteractive"
ENV TZ="America/Los_Angeles"

#Install Graphviz & Python
RUN apt-get update && apt-get install -y sudo graphviz-dev graphviz python3 python3-pip libjpeg8-dev zlib1g-dev libtiff-dev libfreetype6 libfreetype6-dev libwebp-dev libopenjp2-7-dev libopenjp2-7-dev

#Copy Requirements
RUN mkdir /srv/SchedulingGraphAnalysis
COPY requirements.txt /srv/SchedulingGraphAnalysis/.

#Install Dependencies
WORKDIR /srv/SchedulingGraphAnalysis
RUN pip3 install -r requirements.txt
