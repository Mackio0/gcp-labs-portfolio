# Get the IP address name before deleting the address
IP_NAME=$(gcloud compute addresses describe lb-ipv4-1 --global --format="value(name)")

# Delete Global Forwarding Rule
gcloud compute forwarding-rules delete http-content-rule --global -q

# Delete Target HTTP Proxy
gcloud compute target-http-proxies delete http-lb-proxy -q

# Delete URL Map
gcloud compute url-maps delete web-map-http -q

# Remove backend from service
gcloud compute backend-services remove-backend web-backend-service \
    --instance-group=lb-backend-group \
    --instance-group-zone=us-east4-a \
    --global -q

# Delete Backend Service
gcloud compute backend-services delete web-backend-service --global -q

# Delete Health Check
gcloud compute health-checks delete http-basic-check -q

# Delete Static IP
gcloud compute addresses delete lb-ipv4-1 --global -q

# Delete Firewall Rules
gcloud compute firewall-rules delete fw-allow-health-check -q
gcloud compute firewall-rules delete www-firewall-network-lb -q

# Delete Instance Group and Template
gcloud compute instance-groups managed delete lb-backend-group --zone=us-east4-a -q
gcloud compute instance-templates delete lb-backend-template -q

# Delete the non-MIG instances (Task 2 instances)
gcloud compute instances delete www1 www2 www3 --zone us-east4-a -q
