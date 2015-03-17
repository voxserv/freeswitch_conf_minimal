Simple PBX tutorial
===================

Copyright (c) 2015 Stanislav Sinyagin <ssinyagin@k-open.com>

This document is a work in progress.

After installing the minimal config, your FreeSWITCH server is able to
process SIP requests, but its dialplan is empty, so the calls would not
go anywhere. This short tutorial lists the steps to get started with a
simple PBX configuration.

Further in this document, we refer to the standard FreeSWITCH
configuration as "vanilla". The vanilla configuration introduces a
dialplan that demonstrates lots of FreeSWITCH features, but it takes too
much time to clean it up for your future production configuration. Also
the vanilla configuration aliases all domains to the server's IPv4
address, making the domain name part in user registrations
indistinguishable. The minimal configuration enables the "multi-tenant"
scenario, where domain name part of SIP users makes difference. Even if
you're not planning multiple domains on our FreeSWITCH server,
multi-tenant configuration stil has its benefits. One of the benefits is
that you can mix SIP users that connect via IPv4 and IPv6 in the same
domain and let them communicate to each ther.


DNS configuration
-----------------

First of all, you need to choose a domain name for your SIP service. Or
even better, two different domain names: 1) for internal users to use
for SIP client registration; 2) for external SIP peers to send
unauthenticated calls to your server.

In this example, we use `int.example.net` as a domain name for internal
SIP client registrations, and `pub.example.net` as a domain name for
external peers to call out to our server.

Thus, the SIP clients would use accounts like `701@int.example.net` for
registering on our server, and external peers would use SIP URL like
`sip:attendant@pub.example.net` to place unauthenticated calls to our
server.

If you don't plan to receive calls via SIP URL from external peers, the
DNS entry for unauthenticated calls is not necessary (although some ITSP
use this to accept calls on DID numbers).

Most modern SIP clients lookup first a NAPTR DNS record in order to find
out the SIP service that is serving the domain. Some DNS hosting
providers (`godaddy.com`, for example) do not allow adding NAPTR records
via their DNS editing GUI. A simple solution would be to point an NS
record for a subdomain to some alternative DNS hosting, such as
`dns.he.net`.

It is also not too dramatic if there is no NAPTR record for your
domain. Most clients fall back to the SRV record if they don't find a
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
party, or a dialplan application can be executed on it according to the
matching rules and actions.

The vanilla configuration defines two dialplan contexts: "public" is
where all unauthenticated calls are landing, and "default" where calls
to and from registered users are processed.

The minimal configuration defines only the "public" context, leaving you
the freedom to define other contexts as needed.

The structure and contents of a dialplan are described in detail in
FreeSWITCH wiki and in FreeSWITCH book. It is important to understand
the two-pass processing workflow, the `continue` attribute in extensions
and `break` attribute in conditions. Also you need to understand the
meaning of `inline` attribute in the action statements.


`public` dialplan context
-------------------------

The file `dialplan/public/10_gateway_inbound.xml` in the minimal
configuration defines a simple dispatcher for inbound calls from SIP
gateways. It expects the SIP gateway to define two variables:
`target_context` and `domain`, and if both are defined, the inbound call
is transferred into the specified context, with `${domain_name}`
variable set to the domain name. This allows you, for example, to use
multiple SIP trunks in a multi-tenant configuration, so that each trunk
is used for a different tenant and its own context. The following
example of a SIP gateway demonstrates the feature:

```
<!-- File: sip_profiles/external/sipcall.ch.xml -->
  <gateway name="sipcall_41449999990">
    <param name="username" value="41449999990"/>
    <param name="proxy" value="business1.voipgateway.org"/>
    <param name="password" value="xxxxxxxxxx"/>
    <param name="expire-seconds" value="600"/>
    <param name="register" value="true"/>
    <param name="register-transport" value="udp"/>
    <param name="retry-seconds" value="30"/>
    <param name="caller-id-in-from" value="true"/>
    <param name="ping" value="36"/>
    <variables>
      <variable name="domain"
                value="int.example.net" direction="inbound"/>
      <variable name="target_context"
                value="int.example.net" direction="inbound"/>
    </variables>
  </gateway>  
```

Another common approach is to set up matching patterns in the public
context, each matching a particular phone number or a range of numbers,
and making a transfer to a specific extension:

```
<!-- File: dialplan/public/20_inbound_did.xml -->
  <extension name="0449999990">  <!-- Hotline -->
    <condition field="destination_number" expression="^0449999990$">
      <action application="transfer" data="7000 XML int.example.net"/>
    </condition>
  </extension>  
  <extension name="0449999991"> <!-- Automatic Attendant -->
    <condition field="destination_number" expression="^0449999991$">
      <action application="transfer" data="7800 XML int.example.net"/>
    </condition>
  </extension>
```


`int.example.net` dialplan context
----------------------------------

In  this  example,  registered  users  can dial  7xx  to  reach  another
registered  user,  500 for  audio  conference  (unmodetared, anyone  can
join),  and  anything  that starts  with  `0`  or  `1`  or `+`  goes  to
PSTN. Calls to PSTN are processed  in a separate context -- this is done
to simplify  the logic and to  let you manage PSTN  calls from different
internal contexts in a single place.

```
<!-- File: dialplan/int.example.net.xml -->
<include>
  <context name="int.example.net">
  
  <extension name="Local_Extension">
    <condition field="destination_number" expression="^(7\d\d)$">
      <action application="set" data="dialed_extension=$1"/>
      <action application="set" data="ringback=${de-ring}"/>
      <action application="set" data="transfer_ringback=$${hold_music}"/>
      <action application="set" data="call_timeout=60"/>
      <action application="set" data="hangup_after_bridge=true"/>
      <action application="bridge"
              data="user/${dialed_extension}@${domain_name}"/>
    </condition>
  </extension>
  
  <extension name="conference">
    <condition field="destination_number" expression="^500$">
      <action application="answer"/>
      <action application="sleep" data="500"/>
      <action application="conference" data="example_net"/>
    </condition>
  </extension>

  <extension name="pstnout">
    <condition field="destination_number" expression="^[01+]">
      <action application="transfer" data="${destination_number} XML pstnout"/>
    </condition>
  </extension>

  </context>
</include>
```
