# E3S server configuration

## Env files

> Supported env vars can differ from version to version for scaler and router images

### Scaler.env

#### Required variables

* AWS_REGION={Region}
* AWS_CLUSTER=e3s-{Env}
* AWS_TASK_ROLE=e3s-{Env}-task-role
* ZEBRUNNER_ENV={Env}

#### Optional variables

* RESERVE_INSTANCES_PERCENT - Additional weight capacity reservation percent. Default value = 0.25
* RESERVE_MAX_CAPACITY - Max number of additional weight capacity reservation. Default value = 5
* INSTANCE_COOLDOWN_TIMEOUT - Time after instance start when shutdown is prohibited on scale down in time.Duration format. Default value = 4 min
* EXCLUDE_BROWSERS - Excludes selected browser images from registering them as a task definition. Default value = empty
* LOG_LEVEL - Desired log level. Valid levels: `panic`, `fatal`, `error`, `warning`, `info`, `debug`, `trace`. Default value = debug
* IDLE_TIMEOUT - Session idle timeout in time.Duration format. Default value = 1 min
* MAX_TIMEOUT - Maximum valid task/session timeout in time.Duration format. Default value = 24 hours

### Router.env

#### Required variables

* AWS_REGION={Region}
* AWS_CLUSTER=e3s-{Env}
* AWS_TASK_ROLE=e3s-{Env}-task-role
* AWS_LINUX_CAPACITY_PROVIDER=e3s-{Env}-capacityprovider
* AWS_WIN_CAPACITY_PROVIDER=e3s-{Env}-win-capacityprovider
* AWS_TARGET_GROUP=e3s-{Env}-tg
* S3_BUCKET={S3-bucket}
* S3_REGION={Region}
* ZEBRUNNER_ENV={Env}
* USE_PUBLIC_IP=true/false. Default value = false


#### Optional variables

* EXCLUDE_BROWSERS - Excludes selected browser images from registering them as a task definition. Default value = empty
* LOG_LEVEL - Desired log level. Valid levels: `panic`, `fatal`, `error`, `warning`, `info`, `debug`, `trace`. Default value = debug
* IDLE_TIMEOUT - Session idle timeout in time.Duration format. Default value = 1 min
* MAX_TIMEOUT - Maximum valid task/session timeout in time.Duration format. Default value = 24 hours
* SERVICE_STARTUP_TIMEOUT - Task and session startup timeout in time.Duration format. Default value = 10 min
* SESSION_DELETE_TIMEOUT - Session delete timeout in time.Duration format. Default value = 30 sec

## E3S server process management

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

### Examples
* Start e3s server: *./zebrunner.sh start*
* Services seamless restart:  *./zebrunner.sh restart service*
* Stop redis service: *./zebrunner.sh stop data redis*
