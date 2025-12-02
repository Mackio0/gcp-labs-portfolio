gcloud compute instances delete mynet-us-vm  managementnet-us-vm privatenet-us-vm --zone=us-east4-c -q
gcloud compute instances delete mynet-notus-vm --zone=asia-south1-b -q
gcloud compute networks delete managementnet privatenet mynetwork -q
