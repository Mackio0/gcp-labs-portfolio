#!/bin/bash

echo "Check the default VPC network"
# Each subnet is associated with a Google Cloud region and a private RFC 1918 CIDR block for its internal IP addresses range and a gateway.

echo "View the routes"
# In the left pane, click Routes.
# In the Network dropdown list, click default.
# In the Region dropdown list, click us-east4.
# Click View.

echo "View the firewall rules"
echo "Delete all the firewall rules"
echo "Delete the default VPC network"
echo "After deleted, observe there are no routes nor firewall policies"
echo "Try to create a VM instance"
# On the Navigation menu, click Compute Engine > VM instances.
# Click Create Instance.
# Accept the default values and click Create.
# An error is shown on the Networking tab.
# Click Go to Issues.
# In Network Interfaces, notice the No more networks available error under Network interfaces.
# Click Cancel.
echo "Note: As expected, you cannot create a VM instance without a VPC network!"

echo "================================================================================="
echo "=======================Task 2. Create an auto mode network======================="
echo "================================================================================="

echo "In your cloud shell terminal, enables services used in the lab"
gcloud services enable \
iap.googleapis.com \
networkmanagement.googleapis.com

echo "Create an auto mode VPC with firewall rules"
echo "In the Navigation menu (Navigation menu icon), click VPC network > VPC networks.
Click Create VPC network.
For Name, type mynetwork
For Subnet creation mode, click Automatic.
Auto mode networks create subnets in each region automatically.

For Firewall rules, select all available rules.
These are the same standard firewall rules that the default network had. The deny-all-ingress and allow-all-egress rules are also displayed, but you cannot select or disable them because they are implied. These two rules have a lower Priority (higher integers indicate lower priorities) so that the allow ICMP, custom, RDP, and SSH rules are considered first.

Click Create.

When the new network is ready, click mynetwork > Subnets. Note the IP address range for the subnets in us-east4 and asia-south1.

Note: If you ever delete the default network, you can quickly re-create it by creating an auto mode network as you just did."
echo "\n"
echo "Add IAP Firewall Rule"
echo "After the VPC is created, navigate to VPC network > Firewall.

Click Create firewall rule.

Enter the following details:

  Name: allow-iap-ssh

  Network: mynetwork

  Priority: 1000

  Direction of traffic: Ingress

  Action on match: Allow

  Targets: Specified target tags

  Target tags: iap-gce

  Source filter: IPv4 ranges
	
  Source IP ranges: 35.235.240.0/20

  Protocols and ports: Check Specified protocols and ports, then enter: tcp:22

Click Create."

echo "\n"
echo "Create a VM instance in us-east4"
echo "Name: mynet-us-vm, Zone: us-east4-c, Networking - tag: iap-gce"

echo "\n"
echo "Create a VM instance in asia-south1"
echo "Name: mynet-notus-vm, Zone: asia-south1-b, Networking - tag: iap-gce"

echo "Verify connectivity for the VM instances"
echo "SSH into mynet-us-vm from cloudshell and ping the mynet-notus-vm"
echo "Use this command:"
echo "gcloud compute ssh mynet-us-vm \
--zone=us-east4-c \
--tunnel-through-iap"

echo "\n"
echo "Convert the network to a custom mode network"
echo "The auto mode network worked great so far, but you have been asked to convert it to a custom mode network so that new subnets aren't automatically created as new regions become available. This could result in overlap with IP addresses used by manually created subnets or static routes, or could interfere with your overall network planning."

echo "In the Navigation menu (Navigation menu icon), click VPC network > VPC networks.
Click mynetwork to open the network details.
Click Edit.
Select Custom for the Subnet creation mode.
Click Save.
Return to the VPC networks page.
Wait for the Mode of mynetwork to change to Custom."

echo "\n"
echo "================================================================================="
echo "=======================Task 3. Create custom mode networks======================="
echo "================================================================================="
echo "\n"

echo "You have been tasked to create two additional custom networks, managementnet and privatenet, along with firewall rules to allow SSH, ICMP, and RDP ingress traffic and VM instances as shown in this example diagram (with the exception of vm-appliance):"
echo "Note that the IP CIDR ranges of these networks do not overlap. This allows you to set up mechanisms such as VPC peering between the networks. If you specify IP CIDR ranges that are different from your on-premises network, you could even configure hybrid connectivity using VPN or Cloud Interconnect."

echo "Create the managementnet network"
gcloud compute networks create managementnet --project=qwiklabs-gcp-01-2a8a852def45 --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional --bgp-best-path-selection-mode=legacy && gcloud compute networks subnets create NAME --project=qwiklabs-gcp-01-2a8a852def45 --range=IP_RANGE --stack-type=IPV4_ONLY --network=managementnet --region=REGION && gcloud compute networks subnets create managementsubnet-us --project=qwiklabs-gcp-01-2a8a852def45 --range=10.240.0.0/20 --stack-type=IPV4_ONLY --network=managementnet --region=us-east4

echo "Create the privatenet network"
echo "To create the privatenet network, run the following command. Click Authorize if prompted."
gcloud compute networks create privatenet --subnet-mode=custom

echo "To create the privatesubnet-us subnet, run the following command:"
gcloud compute networks subnets create privatesubnet-us --network=privatenet --region=us-east4 --range=172.16.0.0/24

echo "To create the privatesubnet-notus subnet, run the following command:"
gcloud compute networks subnets create privatesubnet-notus --network=privatenet --region=asia-south1 --range=172.20.0.0/20

echo "To list the available VPC networks,"
gcloud compute networks list

echo "To list the available VPC subnets (sorted by VPC network), run the following command:"
gcloud compute networks subnets list --sort-by=NETWORK

echo "Create the firewall rules for managementnet"
gcloud compute --project=qwiklabs-gcp-01-2a8a852def45 firewall-rules create managementnet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=managementnet --action=ALLOW --rules=tcp:22,tcp:3384 --source-ranges=0.0.0.0/0

echo "Create the firewall rules for privatenet"
gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=privatenet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

echo "To list all the firewall rules (sorted by VPC network), run the following command:"
gcloud compute firewall-rules list --sort-by=NETWORK

echo "Create the managementnet-us-vm instance"
gcloud compute instances create managementnet-us-vm --project=qwiklabs-gcp-01-2a8a852def45 --zone=us-east4-c --machine-type=e2-micro --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=managementsubnet-us --metadata=enable-osconfig=TRUE,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=1010116622832-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=managementnet-us-vm,disk-resource-policy=projects/qwiklabs-gcp-01-2a8a852def45/regions/us-east4/resourcePolicies/default-schedule-1,image=projects/debian-cloud/global/images/debian-12-bookworm-v20251111,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud --reservation-affinity=any && printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml && gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-us-east4-c --project=qwiklabs-gcp-01-2a8a852def45 --zone=us-east4-c --file=config.yaml

echo "Create private-us-vm instance"
gcloud compute instances create privatenet-us-vm --zone=us-east4-c --machine-type=e2-micro --subnet=privatesubnet-us --image-family=debian-12 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=privatenet-us-vm

echo "To list all the VM instances (sorted by zone), run the following command:"
gcloud compute instances list --sort-by=ZONE

echo "================================================================================="
echo "===============Task 4. Explore the connectivity across networks=================="
echo "================================================================================="
echo "\n"
echo "SSH into the mynet-us-vm"
echo "gcloud compute ssh mynet-us-vm \
--zone=us-east4-c \
--tunnel-through-iap"

echo "\n"
echo "Ping to 3 other VMs' external IP addresses."
echo "ping -c 3 <Enter mynet-notus-vm's external IP here>"
echo "ping -c 3 <Enter managemnetnet-us-vm's external IP here>"
echo "ping -c 3 <Enter privatenet-us-vm's external IP here>"
echo "They all should works!"

echo "\n"
echo "Ping to 3 other VMs' internal IP addresses."
echo "ping -c 3 <Enter mynet-notus-vm's external IP here>"
echo "ping -c 3 <Enter managementnet-us-vm's external IP here>"
echo "ping -c 3 <Enter privatenet-us-vm's external IP here>"
echo "Only mynet-notus-vm's internal IP should works"

echo "\n"
echo "================================================================================="
echo "==============================Task 5. Review====================================="
echo "================================================================================="

echo "In this lab, you explored the default network and determined that you cannot create VM instances without a VPC network. Thus, you created a new auto mode VPC network with subnets, routes, firewall rules, and two VM instances and tested the connectivity for the VM instances. Because auto mode networks aren't recommended for production, you converted the auto mode network to a custom mode network.
Next, you created two more custom mode VPC networks with firewall rules and VM instances using the Cloud console and the gcloud command line. Then you tested the connectivity across VPC networks, which worked when pinging external IP addresses but not when pinging internal IP addresses.
VPC networks are by default isolated private networking domains. Therefore, no internal IP address communication is allowed between networks, unless you set up mechanisms such as VPC peering or VPN."
