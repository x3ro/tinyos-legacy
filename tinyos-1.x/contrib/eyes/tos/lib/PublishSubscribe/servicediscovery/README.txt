              Service Discovery in the PS Middleware

The implemented service discovery scheme enables applications to
retrieve a list of all attributes IDs present in the network - more
precisely, a list of IDs of all those attributes that one or more
network nodes have registered (wired) in their PSAttributeContainerC.
For that purpose it is only using the services provided by the PS
Middleware, no additional functionality/protocol is required.  The
scheme works as follows:

1.  One node in the network (service discovery sink) subscribes to the
    attribute "AttributeList". The Subscription consists of one
constraint (AttributeList, ANY, 0) and one instruction/command
(AttributeList, X), where X is the set of attributes (a list of all
attribute IDs) currently stored in the repository at the service
discovery sink.  Every time the repository is modified (or at variable
frequency) the subscription is updated (modified) in order to mirror
in X the current list of all attributes.

2.  A publisher node receiving the subscription (the service discovery
    request) will publish a notification with the set of attribute IDs
that it supports (a list of IDs of all those attributes that are
registered (wired) in its PSAttributeContainerC). It will also cache
the attribute list X contained in the command part of the subscription
and create a local (mirrored) repository with it.  

3.  A (local) application request via the PSServiceDiscovery interface
    is thereafter answered by the PSServiceDiscoveryC component with
the list of cached attributes X. 


Features/Limitations: 

- The proposed service discovery scheme is passive: Before a local
  (application initiated) service discovery request can be answered, a
subscription containing the AttributeList X must have been received. 

- No additional (e.g. point-to-point) protocols are required, no
  symmetry of links is required.

- The middleware is agnostic of Service Discovery, because it is
  attribute agnostic and service discovery is implemented as an
attribute. Including service discovery is therefore only a matter of
nesC wiring.

Usage:
- Simply wire PSServiceDiscoveryC to your application and use the
  PSServiceDiscovery interface.
 


