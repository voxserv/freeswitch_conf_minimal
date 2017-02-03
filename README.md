# Minimal FreeSWITCH configuration

This is a minimalistic FreeSWITCH configuration. It does not do anyting,
yet it allows starting the FreeSWITCH daemon and connecting to its
console with fs_cli.

The purpose of this configuration is to provide a base for new projects,
so that you don't have to clean up the vanilla configuration from
unneeded features.

Tested on Debian with packages from [http://files.freeswitch.org].


## Usage if you do everything as root

<pre><code>
cd /tmp
git clone https://github.com/voxserv/freeswitch_conf_minimal.git freeswitch
cp -r freeswitch/overlay/etc/freeswitch /etc/
</code></pre>

## Usage if you work as multiple non-root users

<pre><code>
echo "umask 0007" >>~/.profile 
umask 0007
sudo adduser jsmith freeswitch
sudo mkdir /etc/freeswitch
sudo chgrp freeswitch /etc/freeswitch
sudo chmod g+ws /etc/freeswitch
rm -r /etc/freeswitch
cd /tmp
git clone https://github.com/voxserv/freeswitch_conf_minimal.git freeswitch
cp -r freeswitch/overlay/etc/freeswitch /etc/
</code></pre>

## Usage with Docker

<pre><code>
docker build -t freewswitch .
docker run --rm -it freeswitch
</code></pre>

## Installing FreeSWITCH on Debian Jessie

<pre><code>
apt-get update && apt-get install -y curl git

cat >/etc/apt/sources.list.d/freeswitch.list <<EOT
deb http://files.freeswitch.org/repo/deb/debian/ jessie main
EOT

curl http://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub \
| apt-key add -

apt-get update && apt-get install -y freeswitch-all 
</code></pre>

Further on, you may want to set up your own project-specific Git
repository and push new changes to it.

The following files are empty and are placed there to keep the XML
preprocessor happy. Feel free to delete them after placing your own XML
files:

<pre>
directory/stub.xml
ivr_menus/stub.xml
lang/en/ivr/stub.xml
sip_profiles/external/stub.xml
sip_profiles/internal/stub.xml
</pre>

The SIP profiles are modified to allow multiple domains, as described in
http://wiki.freeswitch.org/wiki/Multi-tenant

sip_profiles/internal.xml
is modified not to alias with any domain in the directory

autoload_configs/local_stream.conf.xml
is modified to match the MOH paths in Debian packages

autoload_configs/logfile.conf.xml
logfile rotation is enabled, debug loglevel is disabled


See also: tutorials in docs/ subfolder


## Author

Stanislav Sinyagin
ssinyagin@k-open.com


