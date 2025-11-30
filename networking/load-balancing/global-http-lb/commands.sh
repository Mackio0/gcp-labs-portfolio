#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)

# List active account Name
gcloud auth list

echo "============================================================================"

# Set and list the cloud project
gcloud config set project $PROJECT_ID
gcloud config list project

echo "======================================================================"
echo "==================Task 1 Set default zone and region=================="
echo "======================================================================"

# Set default region and zone
gcloud config set compute/region us-west1
gcloud config set compute/zone us-west1-b

echo "======================================================================"
echo "==============Task 2. Create multiple web server instances============"
echo "======================================================================"

  gcloud compute instances create www1 \
    --zone=us-west1-b \
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
    --zone=us-west1-b \
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
    --zone=us-west1-b  \
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

# 4. Create a firewall rule to allow external traffic to the VM instances:
gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80

# 5. Get IP addresses of three VMs - EXTERNAL_IP
gcloud compute instances list

echo "======================================================================"
echo "==============Task 3. Create an Application Load Balancer============="
echo "======================================================================"

# Application Load Balancing is implemented on Google Front End (GFE). GFEs are distributed globally and operate together using Google's global network and control plane. You can configure URL rules to route some URLs to one set of instances and route other URLs to other instances.
# Requests are always routed to the instance group that is closest to the user, if that group has enough capacity and is appropriate for the request. If the closest group does not have enough capacity, the request is sent to the closest group that does have capacity.
# To set up a load balancer with a Compute Engine backend, your VMs need to be in an instance group. The managed instance group provides VMs running the backend servers of an external application load balancer. For this lab, backends serve their own hostnames.

# 1. First, create the load balancer template:
gcloud compute instance-templates create lb-backend-template \
   --region=us-west1 \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata=startup-script='#!/bin/bash
     apt-get update
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2'
# Managed instance groups (MIGs) let you operate apps on multiple identical VMs. You can make your workloads scalable and highly available by taking advantage of automated MIG services, including: autoscaling, autohealing, regional (multiple zone) deployment, and automatic updating.

# 2. Create a managed instance group based on the template:
gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone=us-west1-b

# 3. Create the fw-allow-health-check firewall rule.
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

# Note: The ingress rule allows traffic from the Google Cloud health checking systems (130.211.0.0/22 and 35.191.0.0/16). This lab uses the target tag allow-health-check to identify the VMs

# 4. set up a global static external IP address that your customers use to reach your load balancer:
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global
# Notice that the IPv4 address that was reserved:
gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global

# 5. Create a health check for the load balancer (to ensure that only healthy backends are sent traffic):
gcloud compute health-checks create http http-basic-check \
  --port 80

# 6. Create a backend service:
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

# 7. Add your instance group as the backend to the backend service:
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=us-west1-b \
  --global

# 8. Create a URL map to route the incoming requests to the default backend service:
gcloud compute url-maps create web-map-http \
    --default-service web-backend-service

# 9. Create a target HTTP proxy to route requests to your URL map:
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http

# 10. Create a global forwarding rule to route incoming requests to the proxy:
gcloud compute forwarding-rules create http-content-rule \
   --address=lb-ipv4-1\
   --global \
   --target-http-proxy=http-lb-proxy \
   --ports=80
# Note: A forwarding rule and its corresponding IP address represent the frontend configuration of a Google Cloud load balancer. Learn more about the general understanding of forwarding rules from the Forwarding rules overview guide.

echo "======================================================================"
echo "==============Task 4. Test traffic sent to your instances============="
echo "======================================================================"

echo "On the Google Cloud console in the Search field type Load balancing, then choose Load balancing from the search results.

Click on the load balancer that you just created, web-map-http.

In the Backend section, click on the name of the backend and confirm that the VMs are Healthy. If they are not healthy, wait a few moments and try reloading the page.

When the VMs are healthy, test the load balancer using a web browser, going to http://IP_ADDRESS/, replacing IP_ADDRESS with the load balancer's IP address that you copied previously."

echo "============================================================================"
echo "============================================================================"
LB_IPADDR=$(gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global)
echo "Loadbalancer IP:" $LB_IPADDR
echo "Test it from browser using the above IP address!"

echo "============================================================================"
