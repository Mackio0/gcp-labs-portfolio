# Delete Forwarding Rule
gcloud compute forwarding-rules delete www-rule --region us-east4 -q

# Delete Target Pool
gcloud compute target-pools delete www-pool --region us-east4 -q

# Delete Health Check
gcloud compute http-health-checks delete basic-check -q

# Delete Static IP
gcloud compute addresses delete network-lb-ip-1 --region us-east4 -q

# Delete Firewall Rule
gcloud compute firewall-rules delete www-firewall-network-lb -q

# Delete Instances
gcloud compute instances delete www1 www2 www3 --zone us-east4-c -q
