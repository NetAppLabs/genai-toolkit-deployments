# NetApp's GenAI Toolkit

A self-managed cloud native solution with an easy to use UI and API to get started with GenAI, RAG workflows, Chatbots and AI assistants building with unstructured data on Azure NetApp Files or Google Cloud NetApp Volumes. Use it standalone (it has a great UI) or as a component in custom workflows via its API.

## Provides
- Enterprise level Document Search through LLM vector embeddings (auto embeds with built in PGVector DB)
- Chatbot (RAG) UI/API
- Tooling for Chatbots
- RAG model evaluations
- Exportable Smart Prompts/Chatbot endpoints
- (Assistants/Agents TBD)

-----------------------

## Table of Contents
1. [Deploying the Toolkit](#deploying-the-toolkit)
  - [AKS](#aks)
    - [Quickstart](#aks-quickstart)
    - [Requirements](#aks-requirements)
    - [Setting up an ANF Volume](#setting-up-an-anf-volume)
    - [Setting up an AKS Cluster](#setting-up-an-aks-cluster)
    - [Verifying Network Access to the ANF Volume](#verifying-network-access-to-the-anf-volume)
    - [Deployment](#aks-deployment)
  - [GKE](#gke)
    - [Quickstart](#gke-quickstart)
    - [Requirements](#gke-requirements)
    - [Setting up a GCNV Volume](#setting-up-a-gcnv-volume)
    - [Setting up a GKE Cluster](#setting-up-a-gke-cluster)
    - [Verifying Network Access to the GCNV Volume](#verifying-network-access-to-the-gcnv-volume)
    - [Deployment](#gke-deployment)
  - [Local K8s](#local-k8s)
    - [Quickstart](#local-deployment-quickstart)
    - [Requirements](#local-deployment-requirements)
    - [Deployment](#local-deployment)
  - [Extra deployment info](#extra)
    - [Helm Parameters](#helm-parameters)
    - [Required Parameters](#required-parameters)
    - [Optional Parameters](#optional-parameters)
2. [Screenshots](#screenshots)
3. [Changelog](#changelog)
4. [Support](#support)


## Deploying the Toolkit
The toolkit consists of Kubernetes YAML files, packaged as Helm charts, which can be installed on any cluster using Helm. Below are instructions on how to deploy the toolkit to a local Kubernetes cluster, AKS, and GKE. If your environment is already set up, you can use the `Quickstart` section for each deployment method.

### AKS

#### AKS Quickstart
```sh
helm install genai-toolkit genai-toolkit-helmcharts --set cloudProvider="anf",nfs.volumes="1.2.3.4:/path1\,5.6.7.8:/path2"
```
Note the escaped comma in the nfs.volumes list. All commas have to be escaped (for now)

#### AKS Requirements
For ANF, the toolkit requires an AKS cluster, at least one ANF volume, and connectivity between the volumes and the cluster.

#### Setting up an ANF Volume
To get started, follow this guide: [Create an NFS volume for Azure NetApp Files](https://learn.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-create-volumes). Note the vNet where you create the volume. Once the volume is available, proceed to the next step.

#### Setting up an AKS Cluster
Follow this guide: [Quickstart: Deploy an Azure Kubernetes Service (AKS) cluster using Azure portal](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-portal?tabs=azure-cli). Note the vNet where you create the cluster. Once you can run `kubectl` commands locally against the cluster, proceed to the next step.

#### Verifying Network Access to the ANF Volume
To verify network access between your AKS cluster and the ANF volume, follow these steps:

1. **Deploy a test pod**: Deploy a simple test pod in your AKS cluster with tools like `curl` or `ping` installed. Use the following YAML to create a test pod:

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: test-pod
  spec:
    containers:
    - name: test-container
      image: busybox
      command: ['sh', '-c', 'sleep 3600']
      resources:
        limits:
          memory: "128Mi"
          cpu: "500m"
  ```

  Apply the YAML file using `kubectl apply -f test-pod.yaml`.

2. **Access the test pod**: Once the pod is running, access it using:

  ```sh
  kubectl exec -it test-pod -- sh
  ```

3. **Test connectivity**: Inside the pod, use `ping` to test connectivity to the ANF volume's IP address:

  ```sh
  ping <ANF_VOLUME_IP>
  ```

If you receive responses, the network access between the AKS cluster and the ANF volume is properly configured.

### AKS Deployment
Once your Azure resources are set up, deploy the toolkit using:

```sh
helm install genai-toolkit genai-toolkit-helmcharts --set cloudProvider="anf",nfs.volumes="1.2.3.4:/path1\,5.6.7.8:/path2"
```
Note the escaped comma in the nfs.volumes list. All commas have to be escaped (for now)


Replace `nfs.volumes` with the NFS paths of your ANF volumes. This information is available in the mount instructions for the volume.

After the toolkit starts up, get the public IP by running:

```sh
kubectl get svc genai-toolkit-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Use this IP to access the UI in your preferred browser or to make direct API calls.

### GKE

#### GKE Quickstart
```sh
helm install genai-toolkit genai-toolkit-helmcharts --set cloudProvider="gcnv",nfs.volumes="1.2.3.4:/path1\,5.6.7.8:/path2"
```
Note the escaped comma in the nfs.volumes list. All commas have to be escaped (for now)


#### GKE Requirements
For GCNV, the toolkit requires a GKE cluster, at least one GCNV volume, and connectivity between the volumes and the cluster.

#### Setting up a GCNV Volume
To get started, follow this guide: [Create an NFS volume for Google Cloud NetApp Volumes](https://cloud.google.com/netapp/docs/create-volumes). Note the VPC where you create the volume. Once the volume is available, proceed to the next step.

#### Setting up a GKE Cluster
Follow this guide: [Quickstart: Deploy a GKE cluster](https://cloud.google.com/kubernetes-engine/docs/quickstart). Note the VPC where you create the cluster. Once you can run `kubectl` commands locally against the cluster, proceed to the next step.

#### Verifying Network Access to the GCNV Volume
For some reason, you are unable to ping or curl the volumes in GCNV from the cluster. But if they are on the same subnet, you should have access to the volume fromt he cluster.

### GKE Deployment
Once your Google Cloud resources are set up, deploy the toolkit using:

```sh
helm install genai-toolkit genai-toolkit-helmcharts --set cloudProvider="gcnv",nfs.volumes="1.2.3.4:/path1\,5.6.7.8:/path2"
```
Note the escaped comma in the nfs.volumes list. All commas have to be escaped (for now)


Replace `nfs.volumes` with the NFS paths of your ANF volumes. This information is available in the mount instructions for the volume.

After the toolkit starts up, get the public IP by running:

```sh
kubectl get svc genai-toolkit-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Use this IP to access the UI in your preferred browser or to make direct API calls.
### Local K8s

#### Local Deployment Quickstart
```sh
helm install genai-toolkit genai-toolkit-helmcharts --set cloudProvider="local",localDir="/path/to/your/dataset/directory"
```

#### Local Deployment Requirements
For local deployment, you need a local Kubernetes cluster running. You can use Docker Desktop to set up a local Kubernetes cluster. Follow this guide to enable Kubernetes in Docker Desktop: [Docker Desktop - Enable Kubernetes](https://docs.docker.com/desktop/kubernetes/).

We have also tested this on Minikube and Orbstack but theoretically, it should work on any local K8s orchestrator. Note you might have to mount the directory into Minikube first for this to work.

#### Local Deployment
Once your local Kubernetes cluster is set up, deploy the toolkit using:

```sh
helm install genai-toolkit genai-toolkit-helmcharts --set cloudProvider="local",localDir="/path/to/your/dataset/directory\,/path/to/your/second/dataset/directory"
```

Replace `localDir` is a list of absolute paths to your datasets on your local machine. This will mount your local directories into the container as "ONTAP" volumes.

After the toolkit starts up use `localhost` to access the UI in your preferred browser or to make direct API calls.

### Helm Chart Parameters

| Parameter             | Description                                      | Default Value                   | Available values          |
|-----------------------|--------------------------------------------------|---------------------------------|---------------------------|
| `nfs.volumes`         | A list of NFS connection strings                 | `1.2.3.4:/path1,5.6.7.8:/path2` | None                      |
| `cloudProvider`       | The cloud provider to use.                       | `anf`                           | `anf` / `gcnv` / `local`  |
| `db.connectionString` | The database connection string                   | To K8s DB                       |                           |
| `localDir`            | The local directory to use as a dataset "volume" | None                            |                           |                  

Note: By not setting the `db.connectionString` the toolkit will default to use an in cluster database. This is not recommended for production use cases. For testing, it is fine.

There are other optional variables but these are only used for development of the toolkit and do not require any attention.



## Screenshots (on Azure)
![Services](images/services.png)
![Search](images/search.png)
![Save Smart Prompt](images/savesmartprompt.png)
![Image Generation](images/image-generation.png)
![API](images/api.png)



## Changelog
v0.6.0:
- Improved document handling
- Deployment changed to Helm
- Enhanced tooling support
- Switching over to generated clients
- Performance and optimization improvements
- Added system status endpoint

v0.5.0:
- Advanced RAG (BM25 and Query Expansion)
- Support for SmartPrompt tools
- Default tools added (SearXNG)
- Deployment of toolkit changed to kubernetes

v0.4.0:
- RAG config evaluations
- Cross container authentication
- Image model config optional in RAG config
- Enable talking to a model without context (passthrough)
- UI improvements and hardening

v0.3.0:
- Azure Support with Azure NetApp Files
- PGVector is now the default vector database (Can change for Instaclustr or Azure Flex Server)
- RAG evaluations
- SmartPrompts
- Azure OpenAI and OpenAI models

v0.2.0:
- GCP Support with Google Cloud NetApp Volumes
- Prompt API
- Chat UI
- Search/Explore
- Gemini and Claude3 models from VertexAI

## Support
If you encounter any issues with getting the GenAI toolkit up and running or configuring the AI models, please submit an Issue in this repo using the templates (bugs or feedback). You can also visit our [Discussions page](https://github.com/NetAppLabs/genai-toolkit-deployment/discussions).
