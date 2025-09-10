# Usage

> To create aws infrastructure refer to [e3s-terraform-deploy](https://github.com/zebrunner/e3s-terraform-deploy) repository.

To be able to configure and start/down/manage e3s services:

1. Clone this repository to e3s server instance
   ```
   git clone https://github.com/zebrunner/e3s.git && cd e3s
   ```

2. Replace all {Env}, {Account}, {Region}, {S3-bucket} vars in config.env and router.env files

3. Configure any other variable in config.env, router.env, scaler.env, data.env and task-definitions.env if needed


## E3S server configuration

### Env files

> Supported env vars can differ from version to version

#### Config.env

##### Required variables

* AWS_REGION={Region}
* AWS_CLUSTER=e3s-{Env}
* AWS_TASK_ROLE=e3s-{Env}-task-role
* ZEBRUNNER_ENV={Env}

##### Optional variables

* IDLE_TIMEOUT - Session idle timeout in time.Duration format. Default value = 1 min
* MAX_TIMEOUT - Maximum valid task/session timeout in time.Duration format. Default value = 24 hours
* LOG_LEVEL - Desired log level. Valid levels: `panic`, `fatal`, `error`, `warning`, `info`, `debug`, `trace`. Default value = debug
* RECORDING_SHUTDOWN_GRACE_PERIOD - The wait time required to stop recording before sending an exit command to the ECS task in time.Duration format. Default value = 0 sec;

#### Scaler.env

##### Optional variables

* RESERVE_INSTANCES_PERCENT - Additional weight capacity reservation percent. Default value = 0.25
* RESERVE_MAX_CAPACITY - Max number of additional weight capacity reservation. Default value = 5
* INSTANCE_COOLDOWN_TIMEOUT - Time after instance start when shutdown is prohibited on scale down in time.Duration format. Default value = 4 min
* LOST_TASK_COOLDOWN_TIMEOUT - Time after which an unknown (lost) task in ECS cluster will be removed in time.Duration format. Default value = 60 min

#### Router.env

##### Required variables

* AWS_LINUX_CAPACITY_PROVIDER=e3s-{Env}-capacityprovider
* AWS_WIN_CAPACITY_PROVIDER=e3s-{Env}-win-capacityprovider
* AWS_TARGET_GROUP=e3s-{Env}-tg
* S3_BUCKET={S3-bucket}
* S3_REGION={Region}

##### Optional variables

* USE_PUBLIC_IP=true/false. Default value = false
* SERVICE_STARTUP_TIMEOUT - Task and session startup timeout in time.Duration format. Default value = 10 min
* SESSION_DELETE_TIMEOUT - Session delete timeout in time.Duration format. Default value = 30 sec

#### Data.env

##### Optional variables

* POSTGRES_PASSWORD - Password of user, passed in DATABASE var
* DATABASE - Address to postgres
* AWS_ELASTIC_CACHE - Address to redis
* DEFINITIONS_CONNECTION - Address to task-definitions service

#### Task-definitions.env

##### Required variables

* IMAGE_REPOSITORIES - Repositories with supported browsers

##### Optional variables

* EXCLUDE_BROWSERS - Excludes selected browser images from registering them as a task definition. Default value = empty

### E3S server process management

Recomended to use preinstalled ./zebrunner.sh script:

```
Usage: ./zebrunner.sh [option]
      Flags:
          --help | -h                       Print help
      Arguments:
      	  start     [data|service] <name>         Start containers for selected layers
      	  stop      [data|service] <name>         Stop containers for selected layers
      	  down      [data|service] <name>         Stop and remove containers for selected layers
      	  shutdown  [data|service] <name>         Stop, remove containers, clear volumes for selected layers
      	  restart   [data|service] <name>         Down and start containers for selected layers
      	  status                                  Show all containers statuses
          tasks     [list|stop]                   List all tasks or stop them
      	  describe  [cluster|instance|task]       Describe selected items
          instances [list]                        All cluster's container-instances list
```

#### Examples
* Start e3s server: *./zebrunner.sh start*
* Services seamless restart:  *./zebrunner.sh restart service*
* Stop redis service: *./zebrunner.sh stop data redis*

## Errors

If something went wrong during the creation/execution/finish phase, the client will receive an error message from E3S or Selenium. This paragraph will describe the most popular errors from the E3S side.

> To enable exteneded error response by E3S, pass zebrunner:enableDebug=true capability.

#### Selenium type errors:

* name: `session not created`, status: `500`.
    * `failed to start executor` - failed to build an execution environment (browser/version/device is not supported).
    * `service startup timed out` - failed to start service under 9 mins (by default).
    * `error forwarding the new session request timed out waiting for a node to become available` - all nodes are busy, and task didn't start in time (no free resources for task were found).
    * `failed to create task` - failed to find an existing task definition or to place a new task into pending task's pool.
    * `failed to start task` - failed to start healthy (executable) task due to wrong parameters/internal error.
    * `failed to set network configuration` - failed to find host port for newly created task due to any fatal internal error.
    * `failed to start driver` - usually the main reason is a wrong selenium's driver capabilities/driver capabilities format.
    * `service startup failed` - internal error connected with scaler/router/cluster.
    * `service start has been aborted` - task creation has been aborted externally.


* name: `invalid argument`, status: `400`.
    * `failed to process capabilities` - some capabilities are wrong format/type.


* name `invalid session id`, status `404`.
    * `session timed out or not found` - session doesn't exist or cache was already flushed.


* name `session stopped`, status `403`.
    * `session stop reason` - session cannot be accessed anymore because it was finished.


* name `invalid task id`, status `404`.
    * `task timed out or not found` - task doesn't exist or cache was already flushed.


* name `task stopped`, status `403`.
    * `task stop reason` - task cannot be accessed anymore because it was finished.


* name `invalid credentials`, status `401`.
    * `credentials not provided` - request without credentials.
    * `invalid username or password` - invalid credentials.


* name: `unknown error`, status: `500`. Contains other E3S internal errors


### Capabilities

Capabilities could be passed one by one as map{string:any} with prefix `zebrunner:` in key. Example - `"zebrunner:enableDebug":true`.

Or as map{string:map{string:any}}, where the key in the first map should be `zebrunner:options`, and simple keys in the second. Example -  `map{"zebrunner:options": map{"enableVNC":true, "enableVideo":false, "mitm":"false"}}`.

If the same capability but with different values were passed by prefix and map options, value usage priority will be given to the capability with prefix.

#### Supported list

* `enableDebug` - Default: false. Value type: bool/string. Enables extended error response in case of service startup failure.
* `idleTimeout` - Default: 60(seconds = 1 min). Value type: integer/string (in seconds). Session timeout without any interaction before shutdown. Max value - 1200 (20 min).
* `maxTimeout` - Default: 86400(seconds = 24 hours). Value type: integer/string (in seconds). Maximum session duration in seconds.

##### Execution container capabilities:

* `executorVolumes` - Default: empty. Value type: string. Adds additional writable path/paths to executor container, supports multiple values with "," separetor. 
</br>Example: `zebrunner:executorVolumes=/root/.npm` or `zebrunner:executorVolumes=/root/.npm,/tmp`
  
##### Selenium linux browser capabilities:

* `enableVNC` - Default: true. Value type: bool/string. Enables vnc for session.
* `enableVideo` - Default: true. Value type: bool/string. Enables video recording.
* `screenResolution` - Default: 1920x1080x24. Value type: string. Determines session screen resolution. Could be passed only as full or short resolution format. Min screen resolution is 40x30. Max aspect ratio is 1:6 or 6:1.
* `videoScreenSize` - Default: value from screenResolution. Value type: string. Determines recording screen resolution. Cannot be higher than actual screen resolution. Max total pixels: 3_000_000 (example: 1920x1080=2_073_600).
* `frameRate` - Default: 12. Value type: integer/string. Determines video recorder fps. Value could be set between 1 and 30 fps.
* `hostEntries` - Default: -. Value type: string array. Selenoid's [hostEntries](https://aerokube.com/selenoid/latest/#_hosts_entries_hostsentries) capability.
* `dnsServers` - Default: -. Value type: string array. Selenoid's [dnsServers](https://aerokube.com/selenoid/latest/#_custom_dns_servers_dnsservers) capability.
* `timeZone` - Default: utc 0. Value type: string. Specifies a particular time zone in operating system for the session. Example: Asia/Kolkata.
* `mitm` (alias: `Mitm`) - Default: false. Value type: bool/string. Enables mitm proxy. Usage tracker includes allocated resources for mitm container.

##### Selenium windows browser capabilities

* `screenResolution` - Default: 1920x1080x24. Value type: string. Determines session screen resolution. Could be passed only as full or short resolution format. Min screen resolution is 40x30. Max aspect ratio is 1:6 or 6:1.

#### Browsers resource allocation

* `cpu` (alias: `Cpu`) - Value type: integer/string. CPU limitation for executor container measured in [aws units](https://repost.aws/knowledge-center/ecs-cpu-allocation).
* `memory` (alias: `Memory`) - Value type: integer/string. Memory (RAM) limitation for executor container measured in MiB.

> Max limitation for cpu/memory depends on the selected instance type with lowest weight. In case of c5a.4xlarge it will be: cpu: ~16000 memory: ~30000.

| Environment            | Min (cpu, memory) | Default (cpu, memory) |
| ---------------------- | ----------------- | --------------------- |
| Emulators (appium)     | 2048, 2048        | 2048, 2048            |
| Cypress                | 1024, 2048        | 1024, 2048            |
| Linux browser          | 1024, 1024        | 1024, 1024            |
| Windows browser        | 1024, 1024        | 1024, 1024            |

> Max limitation for mitmCpu/mitmMemory is configurable uniquely for every E3S server. Max values by default are also: cpu: 16384, memory: 28675.
* `mitmCpu` (alias: `MitmCpu`, `mitmcpu`) - Min: 512. Default: 512.Value type: integer/string. CPU limitation for mitm container measured in [aws units](https://repost.aws/knowledge-center/ecs-cpu-allocation). 
* `mitmMemory` (alias: `MitmMemory`, `mitmmemory`) - Min: 512. Default: 512. Value type: integer/string. Memory (RAM) limitation for mitm container measured in MiB.
