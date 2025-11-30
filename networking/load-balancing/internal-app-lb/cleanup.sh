#!/bin/bash

# Delete Frontend Resources
gcloud compute firewall-rules delete http2 -q
gcloud compute instances delete frontend --zone us-west1-b -q

# Delete Test Instance
gcloud compute instances delete testinstance --zone us-west1-b -q

# Delete ILB Resources (Reverse Order)
gcloud compute forwarding-rules delete prime-lb --region us-west1 -q
gcloud compute backend-services remove-backend prime-service --instance-group backend --instance-group-zone=us-west1-b --region=us-west1 -q
gcloud compute backend-services delete prime-service --region us-west1 -q
gcloud compute health-checks delete ilb-health -q

# Delete Backend Resources
gcloud compute instance-groups managed delete backend --zone us-west1-b -q
gcloud compute firewall-rules delete http -q
gcloud compute instance-templates delete primecalc -q
