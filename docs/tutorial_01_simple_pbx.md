Simple PBX tutorial
===================

After installing the minimal config, your FreeSWITCH server is able to
process SIP requests, but its dialplan is empty, so the calls would not
go anywhere. This short tutorial lists the steps to get started with a
simple PBX configuration.

DNS configuration
-----------------

First of all, you need to choose a domain name for your SIP service. Or
better two different domain names: 1) for internal users to use for SIP
client registration; 2) for external SIP peers to send unauthenticated
calls to your server.

In this example, we use `int.example.net` as a domain name for internal
SIP client registrations, and `pub.example.net` as a domain name for
external peers to call out to our server.

Thus, the SIP clients would use accounts like `701@int.example.net` for
registering on our server, and external peers would use SIP URL like
`sip:attendant@pub.example.net` to place an unauthenticated call to our
server.

Most modern SIP clients lookup first a NAPTR DNS record in order to find
out the SIP service that is serving the domain. Some DNS hosting
providers (godaddy.com, for example) do not allow adding NAPTR records
via their DNS editing GUI. A simple solution would be to point an NS
record for a subdomain to some alternative DNS hosting, such as
dns.he.net.

It is also not too dramatic if there is no NAPR record for your
domain. Most clients fall back to an SRV record if they don't find a
NAPTR record for the SIP domain.

Also if a Windows server is used as a DNS resolver in your LAN, the
NAPTR record queries may produce unpredictable results. In one occasion,
I had to remove the NAPTR record from a domain, because Gigaset C610IP
phone failed to resolve the service whle Windows server was used as the
default resolver.

A NAPTR record should point to one or several SRV DNS records. The
standard allows you to put a TCP SRV record with a higher priorty, but
not all SIP clients would understand that. FreeSWITCH supports TCP
transport for SIP, listening on the same ports as the UDP transport.

By default, FreeSWITCH uses port 5060 for authenticated SIP requests,
and port 5080 for non-authenticated ones. Thus, the SRV records for
`int.example.net` should point to UDP or TCP port 5060, and use port
5080 for `pub.example.net` records.


The following example creates the records in a BIND name server:

```
;;; inside the zone file for example.net
pbx01               IN A 198.51.100.10
pbx01               IN AAAA 2001:DB8::0A
_sip._udp.int       IN SRV 10 0 5060 pbx01
int                 IN NAPTR 110 100 S SIP+D2U "" _sip._udp.int
_sip._udp.pub       IN SRV 10 0 5080 pbx01
pub                 IN NAPTR 110 100 S SIP+D2U "" _sip._udp.pub
```

Dialplan contexts
-----------------

FreeSWITCH dialplan consists of contexts -- independent sets of matching
rules and actions for the calls. Each call enters a context, and later
it may be transferred to another context, or bridged with some remote
party, or an application, such as playback, can be executed on it
according to the matching rules and actions.