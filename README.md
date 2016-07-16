# GnExec is the execution daemon for GnServer

GnServer calls out to external programs to calculate, for example,
QTL. These external programs can run locally on a server, but also
remotely on a cluster, in the cloud or on a super computer. This
repository contains the code for the daemon that monitors these remote
running programs, gives intermediate progress updates, and returns the
final state.

GnExec is the mechanism for remote processing of longer running
computations. GnExec is implemented in the highly parallel and robust
Elixir programming language on top of the Erlang VM.

# License

The source code is released under the Affero General Public License 3
(AGPLv3). See the LICENSE file.

# Contact

IRC on #genenetwork on irc.freenode.net.

Code and primary web service managed by Dr. Robert W. Williams and the
University of Tennessee Health Science Center, Memphis TN, USA.
