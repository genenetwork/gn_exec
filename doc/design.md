# GnExec design

GnExec is a standalone daemon running on a node to receive commands
for running external processes. These processes can be run locally or
remotely and the daemon should be able to respond to requests both in
push and poll modes. Most jobs are fairly simple and straightforward. I.e. we
do not want to replace job submission systems or work flow engines. All we want here is to

1. Receive a command
2. Execute the command
3. Monitor progress, capture stderr and/or stdout, and feedback status
   to GnServer (say 50% completed) when possible
4. Return exit code and result together

We are using a standalone daemon to make remote communication possible.

Below we describe a typical use case.

# Use case

## Introduction

As a typical example we can run any tool remotely that requires an
input file and generates an output file. Here we simply search for
keywords in an input file using remote grep, counting words

```sh
grep QTL README.md|wc -w > result.out
```

So the result.out file contains '12'. In this case stdout is used for
processing so we can't capture that separately.

## Receive a command

Receiving the command can happen in three ways, depending on the network
setup:

1. Locally through an Erlang socket - typical LAN setup
2. Push through http/https (REST) - typical Cloud setup
3. Through polling when the remote GnExec server can not be connected
   to, but we can poll a GnServer REST interface - typical
   supercomputer setup

The first version only supports local LAN (1).

Commands are defined in Elixir modules. In this example we name the
module ExecGrepWc or something similarly 'descriptive'. We are not
going to pass in 'random' command line strings - only fixed commands
with their inputs are supported by GnExec.

## Execute a command

The module starts up a monitored Erlang service and invokes the external
command. In this case

```sh
grep QTL README.md|wc -w > result.out
```

The parameter 'QTL' and the input file README.md is fetched from the
GnServer. The local commands are already available on the remote
GnExec server. Failure of any of these should result in an error.

## Monitor command

The monitor tracks progress. The only thing it should do now is capture
stdin and stdout.

## Return results

Return the resulting exit code and the resulting file to GnServer.

On error an exit code should be returned with stderr and stdout logs.
