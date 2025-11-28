# 🌍 Global Application Load Balancer (HTTP/S L7) Lab

## Overview
This lab provisions a **Google Cloud Global Application Load Balancer** (Classic External Load Balancer). This is a **Layer 7** load balancer, meaning it inspects and makes routing decisions based on HTTP/HTTPS headers, paths, and hostnames.

The key feature demonstrated here is its **Global** scope, leveraging **Google Front Ends (GFEs)** distributed worldwide to route traffic from the closest edge location to the user.

## Key Components & Architecture

The complexity of the Application Load Balancer is broken down into a chain of components, defining the traffic flow from the internet to the backend:

1.  **Frontend (Entry Point):**
    * **Global Static IP (`lb-ipv4-1`):** The single, global IP address for the service.
    * **Global Forwarding Rule (`http-content-rule`):** Binds the IP to the Target Proxy.
    * **Target HTTP Proxy (`http-lb-proxy`):** Terminates the HTTP connection and inspects the request.

2.  **Routing (The L7 Logic):**
    * **URL Map (`web-map-http`):** Instructs the proxy *where* to send the request (e.g., send all traffic to the default backend service).

3.  **Backend (The Application):**
    * **Backend Service (`web-backend-service`):** Defines common policies like session affinity, health checks, and time-outs.
    * **Health Check (`http-basic-check`):** Verifies that the backend instances are responding correctly to HTTP requests.
    * **Managed Instance Group (MIG):** Contains the actual web server VMs, created from the `lb-backend-template`. It provides auto-healing capabilities.

## Deployment Details

| Component | GCP Type | Purpose |
| :--- | :--- | :--- |
| **VMs** | Managed Instance Group | Hosts the Apache web server and provides unique hostname output. |
| **Startup Script** | Metadata | Installs Apache and uses the instance metadata service to generate a unique response (`Page served from: [hostname]`). |
| **Health Check FW**| Firewall Rule | Crucially allows traffic from Google's health-checking IP ranges (`130.211.0.0/22` and `35.191.0.0/16`). |
| **Scope** | Global | The IP and Frontend components are global, providing a single entry point worldwide. |

## Usage

To deploy the entire Global Application Load Balancer stack, execute the script:

```bash
chmod +x ./networking/load-balancing/global-http-lb/commands.sh
./networking/load-balancing/global-http-lb/commands.sh
```

## Verification

1. Get the Load Balancer IP: The script outputs the final IP address associated with the forwarding rule.

2. Test in Browser: Navigate to http://[LB-IP-ADDRESS].

3. Verify Distribution: Reloading the page multiple times should show output similar to: Page served from: lb-backend-group-xxxx, where the xxxx portion changes, proving the load balancer is distributing traffic across the instances in the MIG.

Note: Initial deployment may take 3-5 minutes for the Health Check to report the instances as Healthy and for the Global IP to propagate across the GFEs

## Clean up 🧹

Run the cleanup.sh script to delete all the resources that was created by commands.sh - [cleanup.sh](./cleanup.sh)
