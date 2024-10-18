#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${BASEDIR}" || exit

graceful_timeout="-t 610"


  start() {
    case "$1" in
      "")
        # start other services
        docker compose -f "$BASEDIR/docker-compose.yaml" up -d
        ;;

      service)
        service_name=$2
        if [ -z "$service_name" ]; then
            docker compose -f "$BASEDIR/docker-compose.yaml" up -d
        else
          docker compose -f "$BASEDIR/docker-compose.yaml" up -d --no-deps "$service_name"
          ret=$?
          if [ $ret -ne 0 ]; then
            echo_warning "Failed to start service $service_name"
            exit 1
          fi
        fi
        ;;

      monitoring)
        service_name=$2
        if [ -z "$service_name" ]; then
            docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" up -d
        else
          docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" up -d --no-deps "$service_name"
          ret=$?
          if [ $ret -ne 0 ]; then
            echo_warning "Failed to start monitoring service $service_name"
            exit 1
          fi
        fi
        ;;

      *)
        echo_warning "Wrong input"
        exit 1
        ;;
    esac
  }

  stop() {
    docker_flags=$3
    case "$1" in
      "")
        # stop services
        docker compose -f "$BASEDIR/docker-compose.yaml" stop $docker_flags
        ;;

      service)
        service_name=$2
        if [ -z "$service_name" ]; then
            docker compose -f "$BASEDIR/docker-compose.yaml" stop $docker_flags
        else
          docker compose -f "$BASEDIR/docker-compose.yaml" stop $docker_flags "$service_name"
          ret=$?
          if [ $ret -ne 0 ]; then
            echo_warning "Failed to stop service $service_name"
            exit 1
          fi
        fi
        ;;

      monitoring)
        service_name=$2
        if [ -z "$service_name" ]; then
            docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" stop $docker_flags
        else
          docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" stop $docker_flags "$service_name"
          ret=$?
          if [ $ret -ne 0 ]; then
            echo_warning "Failed to stop monitoring service $service_name"
            exit 1
          fi
        fi
        ;;

      *)
        echo_warning "Wrong input"
        exit 1
        ;;
    esac
  }

  down() {
    docker_flags=$3
    case "$1" in
      "")
        # down services
        docker compose -f "$BASEDIR/docker-compose.yaml" down $docker_flags
        ;;

      service)
        service_name=$2
        if [ -z "$service_name" ]; then
            docker compose -f "$BASEDIR/docker-compose.yaml" down $docker_flags
        else
          docker compose -f "$BASEDIR/docker-compose.yaml" down $docker_flags "$service_name"
          ret=$?
          if [ $ret -ne 0 ]; then
            echo_warning "Failed to down service $service_name"
            exit 1
          fi
        fi
        ;;

      monitoring)
        service_name=$2
        if [ -z "$service_name" ]; then
            docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" down $docker_flags
        else
          docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" down $docker_flags "$service_name"
          ret=$?
          if [ $ret -ne 0 ]; then
            echo_warning "Failed to down monitoring service $service_name"
            exit 1
          fi
        fi
        ;;

      *)
        echo_warning "Wrong input"
        exit 1
        ;;
    esac
  }

  shutdown() {
    case "$1" in
      "")
        echo_warning "Shutdown will erase all settings and data for \"${BASEDIR}\"!"
        read -r -p "Do you want to continue? (y/n) [y]: "
        if [[ $REPLY =~ ^[Yy]*$ ]]; then
          # shutdown services
          docker compose -f "$BASEDIR/docker-compose.yaml" down -v
          # shutdown prometheus and grafana
          docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" down -v
        fi
        ;;

      service)
        service_name=$2
        if [ -z "$service_name" ]; then
            read -r -p "The entire service layer and its volumes will be deleted. Do you want to continue? (y/n) [y]: "
            if [[ $REPLY =~ ^[Yy]*$ ]]; then
              docker compose -f "$BASEDIR/docker-compose.yaml" down -v
            fi
        else
          read -r -p "$2 and its volumes will be deleted. Do you want to continue? (y/n) [y]: "
            if [[ $REPLY =~ ^[Yy]*$ ]]; then
              docker compose -f "$BASEDIR/docker-compose.yaml" down -v "$service_name"
              ret=$?
              if [ $ret -ne 0 ]; then
                echo_warning "Failed to shutdown service $service_name"
                exit 1
              fi
            fi
        fi
        ;;

      monitoring)
        service_name=$2
        if [ -z "$service_name" ]; then
            read -r -p "The entire service layer and its volumes will be deleted. Do you want to continue? (y/n) [y]: "
            if [[ $REPLY =~ ^[Yy]*$ ]]; then
              docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" down -v
            fi
        else
          read -r -p "$2 and its volumes will be deleted. Do you want to continue? (y/n) [y]: "
            if [[ $REPLY =~ ^[Yy]*$ ]]; then
              docker compose -f "$BASEDIR/monitoring/docker-compose.yaml" down -v "$service_name"
              ret=$?
              if [ $ret -ne 0 ]; then
                echo_warning "Failed to shutdown data $data_name"
                exit 1
              fi
            fi
        fi
        ;;
      *)
        echo_warning "Wrong input"
        exit 1
        ;;
    esac
  }

  logs(){
    case "$1" in
      "")
        docker compose -f "$BASEDIR/docker-compose.yaml" logs -f
        ;;
      *)
        docker logs -f "$1" 2>&1
        ;;
    esac
  }

  graceful_restart() {
    # get all service names and put them into array
    serviceNames=`cat $BASEDIR/docker-compose.yaml | grep -m 4 "container_name" | sed 's/^[   ]*//;s/[    ]*$//' |cut -d " " -f 2`
    readarray -t namesArray <<< "$serviceNames"
    for serviceName in "${namesArray[@]}"
    do
      down "service" "$serviceName" "$graceful_timeout"
      start "service" "$serviceName"
      wait_for_service_to_start "$serviceName"
    done
  }

  wait_for_service_to_start(){
    service_name=$1
    log_to_wait="Service started"
    while true; do
      logs=$( { docker logs $service_name; } 2>&1 )

      logField=`echo "$logs" | grep -m 1 "$log_to_wait"`
      if [ ! -z "$logField" ]; then
        break
      fi


      logField=`echo "$logs" | grep -m 1 "Stopping container..."`
      if [ ! -z "$logField" ]; then
        echo_warning "Failed to start $service_name"
        exit 1
      fi

      sleep 1
    done
  }

  status() {
    watch -n 2 "docker ps --format '{{.Names}}   \t{{.Status}}'"
  }

  tasks() {
    case "$1" in
      list)
        ./scripts/list-tasks.sh
        ;;
      stop)
        ./scripts/stop-tasks.sh
        ;;
      *)
        echo_warning "Wrong input"
        exit 1
        ;;
    esac
  }

  describe() {
    case "$1" in
      cluster)
        ./scripts/describe-cluster.sh
        ;;
      instance)
        ./scripts/describe-instances.sh
        ;;
      task)
        ./scripts/describe-tasks.sh
        ;;
      *)
        echo_warning "Wrong input"
        exit 1
        ;;
    esac
  }

  instances() {
    case "$1" in
      list)
        ./scripts/list-instances.sh
        ;;
      *)
        echo_warning "Wrong input"
        exit 1
        ;;
    esac
  }

  echo_warning() {
    echo "
      WARNING! $1"
  }

  echo_telegram() {
    echo "
      For more help join telegram channel: https://t.me/zebrunner
      "
  }

  echo_help() {
    echo "
      Usage: ./zebrunner.sh [option]
      Flags:
          --help | -h                       Print help
      Arguments:
      	  start     [service|monitoring] <name>   Start containers for selected layers
      	  stop      [service|monitoring] <name>   Stop containers for selected layers
      	  down      [service|monitoring] <name>   Stop and remove containers for selected layers
      	  shutdown  [service|monitoring] <name>   Stop, remove containers, clear volumes for selected layers
      	  restart   [service|monitoring] <name>   Down and start containers for selected layers
          logs      [name]                        Follow logs of certain layer/container
      	  status                                  Show all containers statuses
          tasks     [list|stop]                   List all tasks or stop them
      	  describe  [cluster|instance|task]       Describe selected items
          instances [list]                        All cluster's container-instances list
      	  "
      echo_telegram
      exit 0
  }


case "$1" in
    start)
      start "$2" "$3"
      ;;
    stop)
      read -r -p "Do you want to stop services forcibly? y/n [n]: "
      if [[ $REPLY =~ ^[Nn]*$ ]]; then
        timeout="$graceful_timeout"
      fi

      stop "$2" "$3" "$timeout"
      ;;
    down)
      read -r -p "Do you want to down services forcibly? y/n [n]: "
      if [[ $REPLY =~ ^[Nn]*$ ]]; then
        timeout="$graceful_timeout"
      fi

      down "$2" "$3" "$timeout"
      ;;
    shutdown)
      shutdown "$2" "$3"
      ;;
    restart)
      if [ -z "$3" ] && [[ "$2" == "service" ]]; then
        read -r -p "Do you want to restart services forcibly? y/n [n]: "
        if [[ $REPLY =~ ^[Nn]*$ ]]; then
          graceful_restart
        else
          down "$2" "$3" ""
          start "$2" "$3"
        fi
      else
        read -r -p "Do you want to down services forcibly? y/n [n]: "
        if [[ $REPLY =~ ^[Nn]*$ ]]; then
          timeout="$graceful_timeout"
        fi
        down "$2" "$3" "$timeout"
        start "$2" "$3"
      fi
      ;;
    status)
      status
      ;;
    logs)
      logs "$2"
    ;;
    tasks)
      tasks "$2"
      ;;
    describe)
      describe "$2"
      ;;
    instances)
      instances "$2"
      ;;
    --help | -h)
      echo_help
      ;;
    *)
      echo_help
      exit 1
      ;;
esac
