## nmap-sd is Service Discovery for Passive Registration

Run as a Docker container, the included script will scan the attached /24 network for hosts listening on the specified ports and print a port=>[]address map.

## Why?

I think service registration and discovery tools are a bit heavy for overlay networks, and I like overlay networks. So, rather than force each container contributing a service to also take care of registration this tool will discover hosts contributing known ports. 

# Assumptions

This tool is most useful if you can agree to run only a single service per port. Meaning that all instances of service A run on port Z and instances of service B run on port Y, and so on...


