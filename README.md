# Service Discovery for Passive Registration

Run as a Docker container, the included script will scan the attached /24 network for hosts listening on the specified ports and print a port=>[]address map.

## Why?

I think service registration and discovery tools are a bit heavy for overlay networks, and I like overlay networks. So, rather than force each container contributing a service to also take care of registration this tool will discover hosts contributing known ports. 

## Assumptions

This tool is most useful if you can agree to run only a single service per port. Meaning that all instances of service A run on port Z and instances of service B run on port Y, and so on...

## Behavior

The discovery will run every 30 seconds and take some time to perform the task itself. The runtime currently scales O(N*M) where N is the number of hosts on the overlay network and M is the number of ports that you are scanning. By default, after each pass the script will generate a JSON encoded line to STDOUT. The script will additionally write an authoritative report (named, "report") to a volume mounted at /nmap-sd.

## How Should I Use This?

Run one of these along side your LB and some LB configuration sidekick. The LB configuration sidekick should read the report at /nmap-sd/report and munge the map into an appropriate upstream configuration (which has already been injected into your LB container), and send a SIGHUP to the LB if config has changed. 

Use the repo on Docker Hub allingeek/nmap-sd.

Note: I'm going to write a few of these when I get a second.

## Examples

Suppose you wanted to discover all the nodes on an overlay that were listening on port 80, 2000, 3000, 4000, and 5000. Running the following command would generate a JSON map with the results:

    docker run -it --net demomesh allingeek/nmap-sd 80 2000 3000 4000 5000
    # { "80":[], "2000":["10.0.0.5"], "3000":[], "4000":[], "5000":["10.0.0.8"]}

The following example uses Docker, Docker Machine, Docker Swarm, Consul, and netcat to demonstrate discovery in a full environment.

    # Create a KV machine for clustering and networking
    docker-machine create -d virtualbox kv
    docker $(docker-machine config kv) run -d \
      -p 8500:8500 -h consul \
      progrium/consul
      -server -bootstrap

    # Create a Swarm master
    docker-machine create \
      -d virtualbox \
      --swarm \
      --swarm-master \
      --swarm-discovery="consul://$(docker-machine ip kv):8500" \
      --engine-opt="cluster-store=consul://$(docker-machine ip kv):8500" \
      --engine-opt="cluster-advertise=eth1:2376" \
      c0-master

    # Create two nodes
    docker-machine create \
      -d virtualbox \
      --swarm \
      --swarm-discovery="consul://$(docker-machine ip kv):8500" \
      --engine-opt="cluster-store=consul://$(docker-machine ip kv):8500" \
      --engine-opt="cluster-advertise=eth1:2376" \
      c0-n1
    docker-machine create \
      -d virtualbox \
      --swarm \
      --swarm-discovery="consul://$(docker-machine ip kv):8500" \
      --engine-opt="cluster-store=consul://$(docker-machine ip kv):8500" \
      --engine-opt="cluster-advertise=eth1:2376" \
      c0-n2

    docker $(docker-machine config --swarm c0-master) network create -d overlay mesh

    docker $(docker-machine config --swarm c0-master) run -d --name server1 --net mesh alpine nc -l -p 2000
    docker $(docker-machine config --swarm c0-master) run -d --name server2 --net mesh alpine nc -l -p 2000
    docker $(docker-machine config --swarm c0-master) run -d --name server3 --net mesh alpine nc -l -p 3000
    docker $(docker-machine config --swarm c0-master) run -d --name server4 --net mesh alpine nc -l -p 80

    docker $(docker-machine config --swarm c0-master) run -d --name scanner --net mesh allingeek/nmap-sd 80 2000 3000 4000
    docker $(docker-machine config --swarm c0-master) logs -f scanner

    # Take a few minutes to appreciate the repeated scan then ^C

    docker $(docker-machine config --swarm c0-master) exec -d server4 nc -l -p 2000
    docker $(docker-machine config --swarm c0-master) logs -f scanner

    # Take a few minutes to appreciate the discovery of server4 contributing port 80 then ^C
