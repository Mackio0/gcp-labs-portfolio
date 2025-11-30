#!/bin/bash

# In this lab, you learn how to perform the following tasks:

# Learn about the components that make up an Internal Load Balancer.
# Create a group of backend machines (prime number calculator).
# Set up internal load balancer to direct internal traffic to the backend machines.
# Test the internal load balancer from another internal machine.
# Set up a public-facing web server that uses the internal load balancer to get results from the internal "prime number calculator" service.

# Prerequisites
# Basic familiarity with Google Cloud Compute Engine: Understanding what a Virtual Machine (VM) instance is.
# Basic concepts of networking: What an IP address is.
# Basic Unix/Linux command line: How to type commands in a terminal.
# Some knowledge about VPCs (Virtual Private Clouds): Understanding that your Google Cloud resources live in a private network.

PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"

# List active account Name
echo "===========================Listing Account Name============================="
gcloud auth list
echo "============================================================================"

# Set and list the cloud project
echo "===========================Setting the project ID==========================="
gcloud config set project $PROJECT_ID
gcloud config list project

echo "============================================================================"
echo "====================Setting the project region and zone====================="
echo "============================================================================"
gcloud config set compute/region us-west1
gcloud config set compute/zone us-west1-b

echo "======================================================================"
echo "================Task 1. Create a Virtual Environment=================="
echo "======================================================================"
# A virtual environment keeps your project's software tidy and makes sure your code always runs with the specific versions of tools it needs.
sudo apt-get install -y virtualenv
# Build the virtual environment:
python3 -m venv venv
# Activate the virtual environment:
source venv/bin/activate

echo "======================================================================"
echo "==========Task 2. Create a backend managed instance group============="
echo "======================================================================"
# By using a "managed instance group", Google Cloud can automatically create and maintain identical copies of your service. If one copy fails, Google Cloud replaces it, making your service more reliable.
# Create the startup script
# Script includes a small web server written in Python that can tell you if a number is prime (True) or not (False).
echo "sudo chmod -R 777 /usr/local/sbin/
sudo cat << EOF > /usr/local/sbin/serveprimes.py
import http.server

def is_prime(a): return a!=1 and all(a % i for i in range(2,int(a**0.5)+1))

class myHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(s):
    s.send_response(200)
    s.send_header("Content-type", "text/plain")
    s.end_headers()
    s.wfile.write(bytes(str(is_prime(int(s.path[1:]))).encode('utf-8')))

http.server.HTTPServer(("",80),myHandler).serve_forever()
EOF
nohup python3 /usr/local/sbin/serveprimes.py >/dev/null 2>&1 &" > ~/backend.sh

# Create the instance template
echo "=================Creating instance template=========================="
gcloud compute instance-templates create primecalc \
--metadata-from-file startup-script=backend.sh \
--no-address --tags backend --machine-type=e2-medium
echo "====================================================================="

# Open the firewall
# Run the following command to open the firewall to port 80:
echo "===================Opening firewall port 80=========================="
gcloud compute firewall-rules create http --network default --allow=tcp:80 \
--source-ranges 10.138.0.0/20 --target-tags backend

# Create the instance group
echo "=====================Creating instance group=========================="
gcloud compute instance-groups managed create backend \
--size 3 \
--template primecalc \
--zone us-west1-b

echo "======================================================================"
echo "==============Task 3. Set up the internal load balancer==============="
echo "======================================================================"
# You're creating that single, private VIP entrance for your internal service. It allows other internal applications to reach your "prime number calculator" reliably, without needing to know which specific backend VM is active or available.
# In this task, you set up the Internal Load Balancer and connect it to the instance group you have just created.
# An Internal Load Balancer consists of three main parts:
# Forwarding Rule: This is the actual private IP address that other internal services send requests to. It "forwards" traffic to your backend service.
# Backend Service: This defines how the load balancer distributes traffic to your VM instances. It also includes the health check.
# Health Check: This is a continuous check that monitors the "health" of your backend VMs. The load balancer only sends traffic to machines that are passing their health checks, ensuring your service is always available.

# Create a health check
echo "=======================Creating a health check======================="
gcloud compute health-checks create http ilb-health --request-path /2

# Create a backend service
echo "=====================Creating a backend service======================"
gcloud compute backend-services create prime-service \
--load-balancing-scheme internal --region=us-west1 \
--protocol tcp --health-checks ilb-health

# Add the instance group to the backend service
echo "======================Add the instance group to the backend service====================="
gcloud compute backend-services add-backend prime-service \
--instance-group backend --instance-group-zone=us-west1-b \
--region=us-west1

# Create the forwarding rule
echo "======================Creating the forwarding rule====================="
gcloud compute forwarding-rules create prime-lb \
--load-balancing-scheme internal \
--ports 80 --network default \
--region=us-west1 --address 10.138.0.10 \
--backend-service prime-service

echo "======================================================================"
echo "=====================Task 4. Test the load balancer==================="
echo "======================================================================"
gcloud compute instances create testinstance \
--machine-type=e2-standard-2 --zone us-west1-b
echo "SSH into that testinstace from cloud shell  to curl 10.138.0.10/number. For example curl 10.138.0.10/2" 
echo "======================================================================"

echo "======================================================================"
echo "==============Task 5. Create a public-facing web server==============="
echo "======================================================================"

echo "sudo chmod -R 777 /usr/local/sbin/
sudo cat << EOF > /usr/local/sbin/getprimes.py
import urllib.request
from multiprocessing.dummy import Pool as ThreadPool
import http.server
PREFIX="http://10.138.0.10/" #HTTP Load Balancer
def get_url(number):
    return urllib.request.urlopen(PREFIX+str(number)).read().decode('utf-8')
class myHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(s):
    s.send_response(200)
    s.send_header("Content-type", "text/html")
    s.end_headers()
    i = int(s.path[1:]) if (len(s.path)>1) else 1
    s.wfile.write("<html><body><table>".encode('utf-8'))
    pool = ThreadPool(10)
    results = pool.map(get_url,range(i,i+100))
    for x in range(0,100):
      if not (x % 10): s.wfile.write("<tr>".encode('utf-8'))
      if results[x]=="True":
        s.wfile.write("<td bgcolor='#00ff00'>".encode('utf-8'))
      else:
        s.wfile.write("<td bgcolor='#ff0000'>".encode('utf-8'))
      s.wfile.write(str(x+i).encode('utf-8')+"</td> ".encode('utf-8'))
      if not ((x+1) % 10): s.wfile.write("</tr>".encode('utf-8'))
    s.wfile.write("</table></body></html>".encode('utf-8'))
http.server.HTTPServer(("",80),myHandler).serve_forever()
EOF
nohup python3 /usr/local/sbin/getprimes.py >/dev/null 2>&1 &" > ~/frontend.sh

# Create the frontend instance
gcloud compute instances create frontend --zone=us-west1-b \
--metadata-from-file startup-script=frontend.sh \
--tags frontend --machine-type=e2-standard-2

# Open the firewall for the frontend
gcloud compute firewall-rules create http2 --network default --allow=tcp:80 \
--source-ranges 0.0.0.0/0 --target-tags frontend

# Get the IP frontend VM
IP=$(gcloud compute instances describe frontend --zone=us-west1-b --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

echo "Frontend VM IP addresses is $IP"
echo "Try adding a number to the path, like http://$IP/10000, to see all prime numbers starting from that number."
echo "This concludes the lab" 
echo "=============================================================================================================="
echo "=============================================================================================================="
echo "=============================================================================================================="
