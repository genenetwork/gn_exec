# GnExec
Excute GnServer jobs on remote hosts following an opportunistic or [disperse
computing](http://www.darpa.mil/program/dispersed-computing) approach.

Delegate job execution to volunteer computing

## General Idea

- Dispatch jobs upon client request.
- Collect results and metrics from clients.
- Aggegate metric to learn how better distribute the jobs to clients.
- Distribute the same job multiple times, collect the first computed result.
- Upon client/job resul, wait interaction from other client with the 
  same/similar job and instruct them to continue or terminate their computation.
- Test system, server will provide test data for each required computation
  to perform metrics and verify the ability of the client to satisfy server requests.
- Client declares its available resources, the Central Dipatch Unit (CDU) try to
  match and predict the *optimal* parameters if availabe and estimate the computing time
  to provide a feedback to the end user.
- Metrics:
  - *To Be Defined (TBD)*


## Why REST?

Builing an interoperable decentralized computing infrastructure is a challenging task.

REST will let us develop clients that satisfty specific requirements in terms
of security, infrastructure, platform and OS.

Solid building blocks, Elixir for its semplicity to create reliable services based
on Erlang capabilities dealing with fault tolerance and distributed systems.


## Volunteers

We defined volunteers any client that consumes the GnExec REST API.
Our primary target is to leverage by [GnServer](https://github.com/genenetwork/gn_server)
the computing power of the [BEACON](https://www.nics.tennessee.edu/beacon) at
University of Tennessee in a secure way.


## Todo

- [] search for a formal definition of *Opportunistic Computing* or papers

## References

- Disperse Computing http://www.darpa.mil/program/dispersed-computing
- A Language for Distributed, Eventually Consistent Computations https://lasp-lang.org/
- Elixir Language http://elixir-lang.org/

## API

Client can not list available jobs for to reduce the risk of inspecting workload or server activities.

### Workflow

The system is designed to be stateless, or to minimize the amount of information saved on the server side.
API are versioned to improve functionalities over time. Version 0.1 will be very simple with a limited number of controls and security checks.

Server and client will comunicate over REST, websocket could be used in the future for better control if needed.

List of possible improvements

* client provides information about its computing capabilities
* server dispatch to certain client specific jobs
* server store statistics about clients
* manage clients account
* transferring huge files
* describe the required environment to execute the computation.
    - cpu
    - ram
    - disk
    - software capabilities
    - software environment


### Version 0.1

No secutiry will be implemented, any client can ask for a job and the server will provide it


#### Get a job

    get: /jobs/next

return the job to be executed on the client

    {
        id: integer,
        cmd: string,
        token: string
    }

The job has an `id` that will be used by the client for following cummunications with the server. The client will execute the commands in `cmd`, commands are intended to be execute on a GNU/Linux system. The `token` is used to verify the communication or maybe used similarly to JSON Web Token.

Server store time when it provides the job to a client in order to estimate/evaluate the computing time or decide to not accept results after a certain amount of time.

#### Return the result of the job

    put: /jobs/{id}/result

    further parametes TBD

#### Provide the status of the job

    put: /jobs/{id}/status

    further parametes TBD