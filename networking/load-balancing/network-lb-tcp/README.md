# Network Load Balancer (TCP/UDP) Lab

## Overview
This lab demonstrates the provisioning of a **Google Cloud Network Load Balancer** (External Passthrough). Unlike HTTP(S) Load Balancers which operate at Layer 7, this Network Load Balancer operates at **Layer 4 (Transport Layer)**.

It handles pure TCP/UDP traffic and is regional in scope. In this lab, I provisioned three compute instances running Apache and distributed traffic among them using a legacy Target Pool configuration.

## Architecture
**Traffic Flow:**
`Client` -> `Forwarding Rule (Static IP)` -> `Target Pool` -> `Instances (us-east4)`

* **Type:** External Passthrough Network Load Balancer
* **Scope:** Regional (us-east4)
* **Protocols:** TCP (Port 80)

## Prerequisites
* Google Cloud SDK (`gcloud`) installed and authenticated.
* `jq` installed (for parsing JSON output in the verification step).
* A simplified bash environment (Linux/Mac or Cloud Shell).

## Deployment Steps 🚀

### 1. Environment Setup
The lab sets the default region to `us-east4` to ensure all resources (VMs and LB) reside in the same location, which is a requirement for Target Pool-based load balancers.

### 2. Compute Instances
Three `e2-small` instances (`www1`, `www2`, `www3`) are provisioned.
* **Bootstrapping:** A `startup-script` metadata key is used to install `apache2` and create a custom `index.html` file that identifies the specific server (e.g., "Web Server: www1"). This allows us to visually verify load balancing.

### 3. Networking & Security
* **Firewall:** A rule `www-firewall-network-lb` is created to allow ingress TCP traffic on port 80 to any instance with the tag `network-lb-tag`.
* **Static IP:** A reserved external IP address is created to provide a stable entry point for clients.

### 4. Load Balancer Configuration
* **Health Check:** A legacy HTTP health check probes the instances. If an instance fails, traffic is diverted.
* **Target Pool:** A pool is created referencing the health check, and the three instances are added as members.
* **Forwarding Rule:** This binds the Static IP and Port 80 to the Target Pool.

## Usage

To deploy the infrastructure, ensure you are in the project root and run:

```bash
chmod +x ./networking/load-balancing/network-lb-tcp/commands.sh
./networking/load-balancing/network-lb-tcp/commands.sh
```

## Verification

The script concludes with a continuous curl loop. You will observe the traffic being distributed across the different backends:

```plaintext
<h3>Web Server: www1</h3>
<h3>Web Server: www2</h3>
<h3>Web Server: www1</h3>
<h3>Web Server: www3</h3>
```

Press `CLTR+C` to stop the loop.

## Clean Up 🧹
To avoid incurring charges, delete the resources in the reverse order of creation. I have organized the command in a file called [cleanup.sh](./cleanup.sh)
