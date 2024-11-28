# GenAI Toolkit Terraform Deployment

This project uses Terraform to deploy NetApp's GenAI Toolkit to Azure. 

## Prerequisites

- Terraform installed
- Azure CLI installed and authenticated

## Prerequisites on Azure

- Create an Azure NetApp Files volume and add some files to it if you haven't got any volumes to use already and write down the volume's/volumes' "URL" (IP and volume name/s).
- Enable Azure OpenAI service and create an instance to get your custom Azure OpenAI API URL.
- Create a "Deployment" for each LLM model you want to use. At minimum, you need one chat model, one embedding model, and one image model, e.g., "gpt-4o", "text-embedding-3-large", and "dall-e-3".
- If you don't use the default model names as the deployment names, then you will need to create new Models in GenAI Toolkit or rename existing ones.
- **Note:** Take care to make sure you have matching model deployment versions. For example, the default for "gpt-4" in Azure is not "gpt-4-turbo", but GenAI Toolkit assumes it is. (Side note: We also support OpenAI directly, but most enterprises prefer Azure OpenAI).
- Gather information about your networking, region, etc. Needed for the Terraform variables file and then go deploy!

## Variables

The following variables are used in this Terraform deployment:

- `subscription`: The Azure subscription where the resources will be created.
- `resource_group_name`: The name of the resource group to use.
- `location`: The Azure location where the resources will be created.
- `vnet`: The Azure vnet where the resources will be created. Note that the VM will have to have network access to the volumes to use
- `subnetid`: The Azure subnet where the resources will be created.
- `admin_username`: The admin username used to log into the VM.
- `admin_password`: The admin password used to log into the VM.
- `admin_ssh_key_file_location`: Path to the public key to use for VM access.
- `source_ip_range`: Source IP CIDR that the toolkit will be accessible from (your source IP for instance).
- `anf_volumes`: List of ANF volumes to mount.
- `ontap_volumes`: List of ONTAP volumes to mount.

## Deployment Steps

1. Clone this repository and navigate to the Terraform directory.

   ```bash
   git clone <repository_url>
   cd <terraform_directory>
   ```
2. Initialize Terraform

   ```bash
   terraform init
   ```

3. Edit the `terraform.tfvars` file and specify the values for the variables. Here is an example:

   ```bash
   subscription = "<subscription_id>"
   resource_group_name = "<resource_group_name>"
   location = "<location>"
   vnet = "<vnet>"
   subnetid = "<subnet_id>"
   admin_username = "<admin_username>"
   admin_password = "<admin_password>"
   admin_ssh_key_file_location = "<ssh_key_file_path>"
   source_ip_range = "<source_ip_range>"
   anf_volumes = ["<1.2.3.4:/anf/volume1>", "<1.2.3.4:/anf/volume2>"]
   ontap_volumes = ["<1.2.3.4:/ontap/volume1>", "<1.2.3.4:/ontap/volume2>"]
   ```
   Replace the placeholders with your actual values.


4. Plan the Terraform deployment to see what resources will be created.

   ```bash
   terraform plan
   ```

5. Apply the Terraform deployment to create the resources.

   ```bash
   terraform apply
   ```
   Confirm the deployment by typing `yes` when prompted

   When the deployment is complete, Terraform will output the `app_url`, which will allow you to access the GenAI Toolkit through a browser.

## Getting started with GenAI toolkit

1. Open GenAI Toolkit by navigating your browser to the IP address that the Terraform deployment reported back to you.
2. Register a user account and login (In Preview this is only an email/password pair).
3. Next, you need to configure your global or private API key.
   - In a separate browser window, go to your Azure console and copy your Azure OpenAI instance's "Endpoint" URL and one of the API keys from the "Resource Management > Keys and Endpoint" page under the Azure OpenAI service.
   - Click the top right corner menu of GenAI Toolkit (where you see your email) and go to "API Keys" and select edit on the key "default_azure_openai_key". This is where you paste in the key you copied before from Azure Console and save.
4. Onto the model configuration:
   - Next, click the top right menu again and select "Models". You now need to customize 3 models: a chat model, an embedding model, and an image model (assuming you have deployed Dall-e). If you already added a global "default_azure_openai_key", then select that on each model and add the Endpoint URL you copied earlier.
   - To verify that the model config is correct, you can click the action menu next to each model and select Validate.
5. Lastly, verify at least one of your RAG Configurations is ready. Click the account menu at the top right corner and select "RAG configurations". (A side note: A RAG configuration is responsible for auto embedding (indexing) the data on your volumes and saving the embeddings to the built-in PGVector (Postgres) database. It also defines which models to use and the RAG algorithm-specific parameters like "chunking size").
   - If all 3 of your models are correctly configured, the RAG configuration should show a green "CONFIGURED" under Status. If it doesn't, go back to Models and fix the model that has an "Error" status. You can hover over the status to see the error details.
   - Now that you have at least one working RAG configuration, you can either click the "NetApp" logo at the top left to go back to the Volume and RAG configuration selector and choose your active configuration (this will start the indexing) or you can start the indexing from here in the action menu for the RAG configuration by choosing "Re-index".
6. Go explore! Head back to the front page by clicking the "NetApp" logo at the top left. Indexing can take a while depending on how many files you have and how big they are, but you can start searching/exploring and chatting with your files even if the indexing is not done. The default RAG algorithm does a lot of post-processing after the basic embedding is done. FYI, if you get an "N/A" for a file summary, that just means that it hasn't been indexed yet. The summary is cached in your browser, but you can always refresh/regenerate it by clicking the refresh button in the files table.

