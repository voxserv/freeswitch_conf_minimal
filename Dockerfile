FROM phusion/baseimage:0.9.18
MAINTAINER Nicolás Pace <nico@libre.ws>

RUN echo deb http://files.freeswitch.org/repo/deb/debian/ wheezy main > /etc/apt/sources.list.d/freeswitch.list
RUN curl http://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add -
RUN apt-get update && apt-get install -y curl git freeswitch-meta-all 

RUn rm -r /etc/freeswitch/* || true
ADD overlay/etc/freeswitch/ /etc/freeswitch/
