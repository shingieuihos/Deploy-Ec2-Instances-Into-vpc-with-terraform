1. Save Your Files
Save all the Terraform code you’ve written so far (including the VPC and EC2 instance code) into a .tf file, e.g., main.tf.

Ensure the following files are in the same directory:

main.tf (or split into multiple .tf files—Terraform automatically loads them all)

ShingiNVOfficeKey.pem will be generated locally after provisioning

2. Initialize Terraform
In your terminal or command prompt:

bash
Copy
Edit
terraform init
This downloads the necessary provider plugins (e.g., AWS).

3. Validate the Configuration
bash
Copy
Edit
terraform validate
This checks your syntax and configuration for correctness.

4. Review the Execution Plan
bash
Copy
Edit
terraform plan
This shows you what Terraform will create, modify, or destroy.

Optional: Save the plan to a file:

bash
Copy
Edit
terraform plan -out=tfplan
5. Apply the Configuration
bash
Copy
Edit
terraform apply
Or if you saved a plan:

bash
Copy
Edit
terraform apply tfplan
You’ll be prompted to confirm. Type yes.

6. After Deployment
Once deployed:

Check the AWS Console to see your EC2 instances.

Use the .pem file to RDP into your Windows instances:

Convert .pem to .ppk using PuTTYgen (for Windows RDP)

Or import the key into EC2 Instance Connect if using SSH (for Linux)

For Windows, you’ll use the "Get Windows Password" feature in EC2, providing your .pem file to decrypt the Administrator password.
