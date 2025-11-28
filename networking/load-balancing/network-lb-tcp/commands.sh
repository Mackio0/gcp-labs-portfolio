#!/bin/bash

# Check auth list
gcloud auth list

# Set your project
gcloud config set project <PROJECT_ID>

# List the project ID
gcloud config list project

# Set the default region and then zone
gcloud config set compute/region us-east4
gcloud config set compute/zone us-east4-c

# Create multiple web server instances
  gcloud compute instances create www1 \
    --zone=us-east4-c \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "
<h3>Web Server: www1</h3>" | tee /var/www/html/index.html'

  gcloud compute instances create www2 \
    --zone=us-east4-c \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "
<h3>Web Server: www2</h3>" | tee /var/www/html/index.html'

  gcloud compute instances create www3 \
    --zone=us-east4-c  \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "
<h3>Web Server: www3</h3>" | tee /var/www/html/index.html'

# Create a firewall rule to allow external traffic to the VM instances
gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80

# Get the external IP addresses of your instances and verify that they are running.
# After running this command, You'll see their IP addresses in the EXTERNAL_IP column:
gcloud compute instances list

##  Task 3 Configure the load balancing service
# Create a static external IP address for your load balancer
gcloud compute addresses create network-lb-ip-1 \
  --region us-east4

# Add a legacy HTTP health check resource:
gcloud compute http-health-checks create basic-check

# Create the target pool and forwarding rule
# A target pool is a group of backend instances that receive incoming traffic from external passthrough NLBs. All backend instances of a target pool must reside in the same Google Cloud region.

# Run the following to create the target pool and use the health check, which is required for the service to function:
gcloud compute target-pools create www-pool \
  --region us-east4 --http-health-check basic-check
# Add the instances you created earlier to the pool:
gcloud compute target-pools add-instances www-pool \
    --instances www1,www2,www3

# A forwarding rule specifies how to route network traffic to the backend services of a load balancer. Let's create one.
gcloud compute forwarding-rules create www-rule \
    --region  us-east4 \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool

# The network load balancer is configured, let's test it.
# Enter the following command to view the external IP address of the www-rule forwarding rule used by the load balancer:
gcloud compute forwarding-rules describe www-rule --region us-east4

# Access the external IP address, output with json then using jq
IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region us-east4 --format="json" | jq -r .IPAddress)

# Check the IP address
echo $IPADDRESS

# Send traffic with curl and while loop and watch the html content alternates.
while true; do curl -m1 $IPADDRESS; done;

