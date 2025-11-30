# Regional Internal Load Balancer Lab (Multi-Tier App)

## Overview
This lab provisions a **Regional Internal Application Load Balancer** to create a highly available, private service accessed only by other applications within the Virtual Private Cloud (VPC).

The lab demonstrates a true multi-tier architecture:
1.  **Backend Tier (Prime Calculator):** A private service, load balanced internally, responsible for heavy computational lifting.
2.  **Frontend Tier (Web Server):** A public-facing VM that consumes the internal service via the Internal Load Balancer's **Private IP address**.

## Architecture & Key Concepts

Unlike External Load Balancers, the Internal Load Balancer (ILB) serves a private IP address (`10.138.0.10`) that is only reachable from other VMs within the same VPC network and region (`us-west1`).

* **Load Balancing Scheme:** `internal` (Crucial for ILBs).
* **IP Address:** Private, internal-only IP (`10.138.0.10`).
* **Backend Application:** A Python web server that calculates prime numbers.
* **Frontend Application:** A second Python web server that uses the ILB's private IP to access the backend, proving internal connectivity.
* **Security:** The backend VMs do not have external IP addresses (`--no-address`) and the ILB is protected by the VPC boundary.

## Deployment Breakdown

| Component | Description | Technical Feature Demonstrated |
| :--- | :--- | :--- |
| **Backend Instances** | 3 VMs running the Python "prime calculator" server. | Use of Instance Template (`primecalc`) and Managed Instance Group (MIG). |
| **Backend Firewall** | Allows port 80 traffic only from internal IP ranges (`10.138.0.0/20`). | **Private Service Enforcement:** Ensures the backend is truly inaccessible from the internet. |
| **Load Balancer IP** | The private IP address `10.138.0.10`. | Use of `--load-balancing-scheme internal` and specifying the internal `--address`. |
| **Health Check** | Probes the path `/2` on the backend to verify the service is running. | Standard health checking for internal services. |
| **Frontend VM** | Public-facing server that makes requests to `http://10.138.0.10/`. | **Multi-Tier Communication:** Shows internal apps consuming ILB services. |

## Usage

To deploy the entire environment, execute the script:

```bash
# This is the relative path from root directory, if you only clone this lab repo, please change it accordingly.
chmod +x ./networking/load-balancing/internal-app-lb/commands.sh
./networking/load-balancing/internal-app-lb/commands.sh
```

## Verification

Verification is done in two stages, confirming both internal and external access:

### Stage 1: Internal Test

The script creates a `testinstance`. You must SSH into this internal VM to verify the ILB's private IP works:

```bash
gcloud compute ssh testinstance --zone us-west1-b --command "curl 10.138.0.10/17"
# Expected Output: True (or False, depending on the number)
```

This step confirms that the Backend Tier is accessible only via the private IP.

### Stage 2: External/Multi-Tier Test

1. Use your browser to access the public IP of the Frontend VM that uses the ILB:
2. Find the public IP address printed by the script (Frontend VM IP addresses is...).
3. Navigate to the IP address in your browser: http://[FRONTEND-VM-IP]/
4. Advanced Test: Append a number to the path (e.g., http://[FRONTEND-VM-IP]/10000). The frontend will make 100 concurrent requests to the ILB (10.138.0.10), which then distributes the requests across the backend MIG.

## Cleanup 🧹

Run the cleanup.sh script to delete all the resources that was created by commands.sh - [cleanup.sh](./cleanup.sh)
