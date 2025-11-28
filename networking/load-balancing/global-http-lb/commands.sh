#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)

# List active account Name
gcloud auth list

echo "============================================================================"

# Set and list the cloud project
gcloud config set project $PROJECT_ID
gcloud config list project

echo "============================================================================"

# Set the default region and Zone
gcloud config set compute/region us-east4
gcloud config set compute/zone us-east4-a

echo "============================================================================"
echo "==================================TASK 2===================================="

# Task 2: Create multiple web servers
# The following commands create three Compute Engine VM instances and install Apache on them, then add a firewall rule that allows HTTP traffic to reach the instances. Setting the tags field lets you reference these instances all at once, such as with a firewall rule. These commands also install Apache on each instance and gives each instance a unique home page.
  gcloud compute instances create www1 \
    --zone=us-east4-a \
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
    --zone=us-east4-a \
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
    --zone=us-east4-a  \
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

echo "============================================================================"

# Create a firewall rule to allow external traffic to the VM instances:
gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80

echo "============================================================================"

# Get the EXTERNAL_IP of the instances to test they are working or not
gcloud compute instances list
# curl http://[ip_address]

echo "============================================================================"
echo "===================================TASK 3===================================" 

# Task 3 Create an application load balancer
# Application Load Balancing is implemented on Google Front End (GFE). GFEs are distributed globally and operate together using Google's global network and control plane. You can configure URL rules to route some URLs to one set of instances and route other URLs to other instances.
# Requests are always routed to the instance group that is closest to the user, if that group has enough capacity and is appropriate for the request. If the closest group does not have enough capacity, the request is sent to the closest group that does have capacity.
# To set up a load balancer with a Compute Engine backend, your VMs need to be in an instance group. The managed instance group provides VMs running the backend servers of an external application load balancer. For this lab, backends serve their own hostnames.

# 1. First, create the load balancer template:
gcloud compute instance-templates create lb-backend-template \
   --region=us-east4 \
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

echo "============================================================================"

# Managed instance groups (MIGs) let you operate apps on multiple identical VMs. You can make your workloads scalable and highly available by taking advantage of automated MIG services, including: autoscaling, autohealing, regional (multiple zone) deployment, and automatic updating.

# 2. Create a managed instance group based on the template:
gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone=us-east4-a

# 3. Create the fw-allow-health-check firewall rule:
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

# Note: The ingress rule allows traffic from the Google Cloud health checking systems (130.211.0.0/22 and 35.191.0.0/16). This lab uses the target tag allow-health-check to identify the VMs
echo "============================================================================"

# 4. Set up an global static external IP address that will be assosiciated with LB
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global
# Notice the IP address that was reserved:
gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global

echo "============================================================================"

# 5. Create a health check for the load balancer (to ensure that only healthy backends are sent traffic):
gcloud compute health-checks create http http-basic-check \
  --port 80

echo "============================================================================"

# 6. Create a backend service:
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

# 7. Add your instance group as the backend to the backend service:
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=us-east4-a \
  --global

echo "============================================================================"

# 8. Create a URL map to route the incoming requests to the default backend service:
gcloud compute url-maps create web-map-http \
    --default-service web-backend-service
# Note: URL map is a Google Cloud configuration resource used to route requests to backend services or backend buckets. For example, with an external Application Load Balancer, you can use a single URL map to route requests to different destinations based on the rules configured in the URL map:
# - Requests for https://example.com/video go to one backend service.
# - Requests for https://example.com/audio go to a different backend service.
# - Requests for https://example.com/images go to a Cloud Storage backend bucket.
# - Requests for any other host and path combination go to a default backend service.

echo "============================================================================"

# 9. Create a target HTTP proxy to route requests to your URL map:
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http

echo "============================================================================"

# 10. Create a global forwarding rule to route incoming requests to the proxy:
gcloud compute forwarding-rules create http-content-rule \
   --address=lb-ipv4-1\
   --global \
   --target-http-proxy=http-lb-proxy \
   --ports=80

echo "============================================================================"

# Note: A forwarding rule and its corresponding IP address represent the frontend configuration of a Google Cloud load balancer. Learn more about the general understanding of forwarding rules from the Forwarding rules overview [https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts] guide.

echo "===================Test traffic sent to your instances======================"
echo "============================================================================"

# On the Google Cloud console in the Search field type Load balancing, then choose Load balancing from the search results.
# Click on the load balancer that you just created, web-map-http.

# In the Backend section, click on the name of the backend and confirm that the VMs are Healthy. If they are not healthy, wait a few moments and try reloading the page.
# When the VMs are healthy, test the load balancer using a web browser, going to http://IP_ADDRESS/, replacing IP_ADDRESS with the load balancer's IP address that you copied previously.

# Note: This may take three to five minutes. If you do not connect, wait a minute, and then reload the browser.
# Your browser should render a page with content showing the name of the instance that served the page, along with its zone (for example, Page served from: lb-backend-group-xxxx).

echo "============================================================================"
echo "============================================================================"
LB_IPADDR=$(gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global)
echo "Loadbalancer IP:" $LB_IPADDR
echo "Test it from browser using the above IP address!"
 
echo "============================================================================"

