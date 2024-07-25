# tf-gcp-infra
### Install and Set Up Tools
1. Install the Google Cloud SDK (gcloud CLI).
2. Install Terraform.
First create GCP project from the google cloud console.
In this case , we have created "csye-6225-rcp".
After that we need to enable service api 

## Enable GCP Service APIs

Google Cloud Platform requires you to enable services (APIs) before you can use them. 
To enable gcp service apis, 
1. Navigate to the Google Cloud Console.
2. Go to the "APIs & Services" > "Library" page.
3. Search for the Compute Engine API and Cloud OS Login API and enable them for your project.


### Create Virtual Private Cloud (VPC)
For now we are creating VPC with the following properties:
- Auto-create subnets should be disabled.
- Routing mode should be set to regional.
- No default routes should be created.

### Create two Subnets in our VPC
- Create 2 subnets in the VPC: one named "webapp" and the other named "db".
- Each subnet should have a /24 CIDR address range.
- Add a route to 0.0.0.0/0 with the next hop to Internet Gateway and attach it to your VPC applied webapp subnet.


### How to run the Terraform
- Terraform init
- Terraform plan
- Terraform apply
