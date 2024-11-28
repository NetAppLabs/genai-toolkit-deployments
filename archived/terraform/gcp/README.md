# GenAI Toolkit Terraform Deployment

This project uses Terraform to deploy NetApp's GenAI Toolkit to Google Cloud Platform (GCP). 

## Prerequisites for Deployment

- Terraform installed
- Google Cloud SDK (gcloud) installed and authenticated

## Prerequisites on Google Cloud

- Create a Google Cloud NetApp Volumes volume and add some files to it if you haven't got any volumes to use already and write down the volume's/volumes' "URL" (IP and volume name/s).
- Enable VertexAI services and APIs so that you have some LLMs to talk to.
- We support all Gemini models as well as Claude3 models from the VertexAI model garden (may need to enable each individually for Claude).
- At minimum, you need one chat model, one embedding model, and one image model, e.g., "gemini-1.5-flash-001", "text-embedding-004", and "imagegeneration".
- Once you have enabled VertexAI, you will need to export a service account JSON file to use with the Terraform deployment if you want to set a global access key for all users of your instance of GenAI Toolkit. Alternatively, each user can create their own key after login.
- You need compute access rights on the service account used to create the VM.
- Gather information about your networking, region, etc. Needed for the Terraform variables file and then go deploy!

## Variables

The following variables are used in this Terraform deployment:

- `project`: The GCP project to use.
- `region`: The region where the resources will be created.
- `zone`: The zone where the resources will be created.
- `network`: The network to use for the instance.
- `subnetwork`: The subnetwork to use for the instance.
- `firewall_tags`: List of tags to apply to the firewall rules.
- `source_ranges`: A list of source ranges.
- `service_account_json_file_path`: Path to service account JSON for gcloud.
- `gcnv_volumes`: List of GCNV NFS volumes to mount.
- `ontap_volumes`: List of ONTAP NFS volumes to mount.

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
   project = "<project_id>"
   region = "<region>"
   zone = "<zone>"
   network = "<network>"
   subnetwork = "<subnetwork>"
   firewall_tags = ["http-server", "https-server"]
   source_ranges = ["<source_range1>", "<source_range2>"]
   service_account_json_file_path = "<service_account_json_file_path>"
   gcnv_volumes = ["<1.2.3.4:/gcnv/volume1>", "<1.2.3.4:/gcnv/volume2>"]
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
3. Next, you need to configure your global VertexAI service account (if you didn't in the Terraform deployment) or a private VertexAI key.
   - If you haven't fetched a service account JSON file, then in a separate browser window go to your "APIs & Services Credentials" page and create a Service Account and export the JSON file (you will need the contents of the file).
   - The VertexAI service account needs to have the "Vertex AI Service Agent" role.
   - Then in the GenAI Toolkit browser window, click the top right corner menu of GenAI Toolkit (where you see your email) and go to "API Keys" and select edit on the key "default_vertex_key". This is where you paste in your Service account JSON file's contents and save. Make sure you select "json" as the key type.
4. Onto the model configuration:
   - Next, click the top right menu again and select "Models". You now need to customize 3 models: a chat model, an embedding model, and an image model (assuming you have deployed Dall-e). If you already added a global "default_vertex_key" then select that on each model and save.
   - To verify that the model config is correct, you can click the action menu next to each model and select Validate.
5. Lastly, verify at least one of your RAG Configurations is ready. Click the account menu at the top right corner and select "RAG configurations". (A side note: a RAG configuration is responsible for auto embedding (indexing) the data on your volumes and saving the embeddings to the built-in PGVector (Postgres) database. It also defines which models to use and the RAG algorithm-specific parameters like "chunking size").
   - If all 3 of your models are correctly configured, the RAG configuration should show a green "CONFIGURED" under Status. If it doesn't, go back to Models and fix the model that has an "Error" status. You can hover over the status to see the error details.
   - Now that you have at least one working RAG configuration, you can either click the "NetApp" logo at the top left to go back to the Volume and RAG configuration selector and choose your active configuration (this will start the indexing) or you can start the indexing from here in the action menu for the RAG configuration by choosing "Re-index".
6. Go explore! Head back to the front page by clicking the "NetApp" logo at the top left. Indexing can take a while depending on how many files you have and how big they are, but you can start searching/exploring and chatting with your files even if the indexing is not done. The default RAG algorithm does a lot of post-processing after the basic embedding is done. FYI, if you get an "N/A" for a file summary, that just means that it hasn't been indexed yet. The summary is cached in your browser, but you can always refresh/regenerate it by clicking the refresh button in the files table.
