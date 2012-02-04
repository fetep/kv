# kv

kv is a simple file-backed key-value store.

Inside a kv database ("kvdb"), there exists a set of nodes. Each node
has it's own set of key-value data.

Nodes use "/" for namespace. Example node names: "host/bar", "switch/foo".

Keys use "." for namespace. Example key names: "hardware.cpu_model", "foo".

The full canonical "path" for a value includes the node and the key name.
Example path: "host/bar.hardware.cpu_model".

## Data File Format
...

## File backed?

kv's design goal is not fancy data storage or massive write performance,
it is data portability and ease of access.

The backend data files should be checked into revision control, which
makes it easy for other systems to get at the data, provides an audit
log, basic ACLs, and rollback capability.

## The Vision

kv is just a library. Eventually there will be sample frontends that
use kv on the backend, and expose the data. Ideas:

* kv - command line tool to read/write/manipulate a kvdb
* kvlookupd - loads all kv nodes in an in-memory searchable index,
  provides a way to query over the network. periodically stat()-polls
  and updates kv node data (and indexes).
* kvrest - read-only REST api
