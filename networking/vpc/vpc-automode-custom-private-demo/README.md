# VPC Modes & Network Isolation Lab

## Overview

This lab explores the fundamental building blocks of Google Cloud networking: **Virtual Private Clouds (VPCs)**. It demonstrates the differences between **Auto Mode** and **Custom Mode** networks and validates network isolation principles.

The goal is to prove that VPCs are global resources composed of regional subnets, and that distinct VPCs are logically isolated from one another unless explicitly peered.

## Architecture

![Overview of architecture](./overview.png)

The lab builds three distinct network environments:

1.  **`mynetwork` (Auto Mode -> Custom Mode):**
    * Starts as Auto Mode (subnets in every region).
    * Converted to Custom Mode (manual subnet management).
    * **Scope:** Global resource, Regional subnets (`us-east4`, `asia-south1`).

2.  **`managementnet` (Custom Mode):**
    * Strictly defined subnets.
    * **Subnet:** `10.240.0.0/20` (us-east4).

3.  **`privatenet` (Custom Mode):**
    * Strictly defined subnets.
    * **Subnets:** `172.16.0.0/24` (us-east4), `172.20.0.0/20` (asia-south1).

## Experiments & Observations 🧪

| Experiment | Connection Type | Result | Explanation |
| :--- | :--- | :--- | :--- |
| **VM to VM (Same VPC)** | Internal IP | ✅ Success | VMs in the same VPC can communicate via internal IP, even across regions. |
| **VM to VM (Diff VPC)** | External IP | ✅ Success | Traffic exits one VPC to the internet and enters the other via public IP. |
| **VM to VM (Diff VPC)** | Internal IP | ❌ Fail | VPCs are isolated domains. RFC1918 traffic cannot cross boundaries without Peering/VPN. |
| **No VPC** | N/A | ❌ Fail | You cannot create a VM without a valid network interface. |

## Deployment Steps

### Part 1: Manual Exploration (Console)
The initial steps of this lab (Task 1 & 2) involve exploring the Default VPC and creating the Auto Mode network via the Google Cloud Console to understand the UI workflows.
* *See `walkthrough.sh` for the specific configuration values used during the UI setup.*

### Part 2: Automated Deployment (CLI)
Task 3 (Custom VPCs) uses the `gcloud` CLI to provision resources efficiently.

```bash
# Set your project ID
export PROJECT_ID=[YOUR_PROJECT_ID]

# Create Custom VPCs
gcloud compute networks create managementnet --subnet-mode=custom
gcloud compute networks create privatenet --subnet-mode=custom

# Create Subnets
gcloud compute networks subnets create managementsubnet-us \
    --network=managementnet --region=us-east4 --range=10.240.0.0/20

gcloud compute networks subnets create privatesubnet-us \
    --network=privatenet --region=us-east4 --range=172.16.0.0/24

# Create Firewall Rules (Allow SSH/ICMP)
gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp \
    --network=managementnet --action=ALLOW --rules=tcp:22,tcp:3389,icmp --source-ranges=0.0.0.0/0
```

## Verification

1. SSH into `mynet-us-vm` (in mynetwork).

2. Ping `mynet-notus-vm` (Internal IP): Success (Same VPC).

3. Ping `managementnet-us-vm` (Internal IP): Fail (Different VPC, Isolated).

4. Ping `managementnet-us-vm` (External IP): Success (Routed via Internet).

5. Ping `privatenet-us-vm` (Internal IP): Fail (Different VPC, Isolated). 

6. Ping `privatenet-us-vm` (External IP): Success (Routed via Internet).

## Cleanup

Run the `cleanup.sh` script to delete all the resources in the lab - [cleanup.sh](./cleanup.sh)
