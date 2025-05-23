# NetApp's GenAI Toolkit

☁️ A self-managed, cloud-native solution with an easy-to-use UI and API. 

Get started using your unstructured data to build with GenAI, RAG workflows, Chatbots, and AI assistants on Azure NetApp Files or Google Cloud NetApp Volumes. Use it on its own with the intuitive UI, or leverage the API to build your own custom workflows.

## Disclaimer
This repository contains the automation scripts to set up NetApp's GenAI toolkit. The configurations herein and automation scripts are provided as is under the MIT license.

## Provides
- Enterprise level Document Search through LLM vector embeddings (auto embeds with built-in PGVector DB)
- Chatbot (RAG) UI/API
- Tooling for Chatbots
- RAG model evaluations
- Exportable Smart Prompts/Chatbot endpoints
- (Assistants/Agents TBD)

-----------------------

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Deploying the Toolkit](#deploying-the-toolkit)
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
3. [Advanced](#advanced)
    - [Helm Chart Parameters](#helm-chart-parameters)
4. [Screenshots](#screenshots)
5. [Changelog](#changelog)
6. [Support](#support)



## Prerequisites

The installation requires that you have an already created Kubernetes cluster, either running locally or in the Cloud.

The installation requires [just](https://just.systems/man/en/) which is installable via a package manager like e.g. with brew:

```sh
brew install just
```

It also requires the following tools:

  - [kubectl](https://kubernetes.io/docs/reference/kubectl/)
  - [helm](https://helm.sh)
  - [jq](https://jqlang.org/manual/)
  - [yq](https://mikefarah.gitbook.io/yq)
  - [envsubst](https://formulae.brew.sh/formula/gettext)


## Deploying the Toolkit
The deployment consists of Kubernetes YAML files, packaged as Helm charts, which can be installed on any cluster using Helm. Below are instructions on how to deploy the toolkit to a local Kubernetes cluster, AKS, and GKE. If your environment is already set up, you can use the `Quickstart` section for each deployment method.

### AKS


#### AKS Quickstart

With existing ANF nfsv3 volumes:

```sh
just install nfs://1.2.3.4/export1,nfs://5.6.7.8/export2 AZURE
```

With existing ANF SMB volumes:

```sh
just install smb://smbuser:smbpass@smbserver/share?sec=ntlmssp AZURE
```


#### AKS Requirements
For ANF, the toolkit requires an AKS cluster, at least one ANF volume, and connectivity between the volumes and the cluster.

#### Setting up an ANF Volume
To get started, follow the guides for [Create an SMB volume for Azure NetApp Files](https://learn.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-create-volumes-smb) or  [Create an NFS volume for Azure NetApp Files](https://learn.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-create-volumes). Note the vNet where you create the volume. Once the volume is available, proceed to the next step.

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

#### AKS Deployment

With existing ANF nfsv3 volumes:

```sh
just install nfs://1.2.3.4/export1,nfs://5.6.7.8/export2 AZURE
```

With existing ANF SMB volumes:

```sh
just install smb://smbuser:smbpass@smbserver/share?sec=ntlmssp AZURE
```

After the toolkit starts up, get the public IP by running:

```sh
kubectl get svc genai-toolkit-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Use this IP to access the UI in your preferred browser or to make direct API calls.

### GKE

#### GKE Quickstart


```sh
just install smb://smbuser:smbpass@smbserver/share?sec=ntlmssp
```


#### GKE Requirements
For GCNV, the toolkit requires a GKE cluster, at least one GCNV volume, and connectivity between the volumes and the cluster.

#### Setting up a GCNV Volume
To get started, follow this guide: [Create an volume for Google Cloud NetApp Volumes](https://cloud.google.com/netapp/volumes/docs/configure-and-use/volumes/create-volume). Note the VPC where you create the volume. Once the volume is available, proceed to the next step.

#### Setting up a GKE Cluster
Follow this guide: [Quickstart: Deploy a GKE cluster](https://cloud.google.com/kubernetes-engine/docs/quickstart). Note the VPC where you create the cluster. Once you can run `kubectl` commands locally against the cluster, proceed to the next step.

#### Verifying Network Access to the GCNV Volume
For some reason, you are unable to ping or curl the volumes in GCNV from the cluster. But if they are on the same subnet, you should have access to the volume from the cluster.

### GKE Deployment
Once your Google Cloud resources are set up, deploy the toolkit using:


With existing GCNV nfsv3 volumes:

```sh
just install nfs://1.2.3.4/export1,nfs://5.6.7.8/export2
```

With existing GCNV SMB volumes:

```sh
just install smb://smbuser:smbpass@smbserver/share?sec=ntlmssp
```

After the toolkit starts up, get the public IP by running:

```sh
kubectl get svc genai-toolkit-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Use this IP to access the UI in your preferred browser or to make direct API calls.

### Local K8s

#### Local Deployment Quickstart

With existing local directories:

```sh
just install /path/to/your/dataset/directory,/path/to/your/second/dataset/directory
```

Note: the directories will be mounted into the local k8s cluster

With existing ANF nfsv3 volumes:

```sh
just install nfs://1.2.3.4/export1,nfs://5.6.7.8/export2
```

With existing ANF SMB volumes:

```sh
just install smb://smbuser:smbpass@smbserver/share?sec=ntlmssp
```


#### Local Deployment Requirements
For local deployment, you need a local Kubernetes cluster running. You can use Docker Desktop to set up a local Kubernetes cluster. Follow this guide to enable Kubernetes in Docker Desktop: [Docker Desktop - Enable Kubernetes](https://docs.docker.com/desktop/kubernetes/).

We have also tested this on Minikube and Orbstack but theoretically, it should work on any local K8s orchestrator. Note you might have to mount the directory into Minikube first for this to work.

#### Local Deployment
Once your local Kubernetes cluster is set up, deploy the toolkit using:

```sh
just install /path/to/your/dataset/directory,/path/to/your/second/dataset/directory
```

After the toolkit starts up, use `localhost` to access the UI in your preferred browser or to make direct API calls.

## Advanced

### Helm Chart Parameters

#### GenAI Toolkit Helm Chart Options - found in [charts/genai-toolkit/values.yaml](./charts/genai-toolkit/values.yaml)

| Parameter             | Description                                      | Default Value                   | Available values          |
|-----------------------|--------------------------------------------------|---------------------------------|---------------------------|
| `nfs.volumes`         | A list of NFS connection strings                 | None                            |                           |
| `smb.volumes`         | A list of SMB connection strings                 | None                            |                           |
| `db.connectionString` | The database connection string                   | To K8s DB                       |                           |

Note: By not setting the `db.connectionString` the toolkit will default to use an in cluster database. This is not recommended for production use cases. For testing, it is fine.

There are other optional variables but these are only used for development of the toolkit and do not require any attention.


**Note**: To use native Azure Queue Storage with an Azure Storage connection string - the following three options must be modified:

1. Event Distributor Helm Chart [values.yaml](./event-distributor/values.yaml)

| Parameter             | Description                        | Default Value                                                                                                                                                                  | Available values                                                                                                |
|-----------------------|------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| `AzureWebJobsStorage` | An Azure Storage connection string | Defaults to using the connection string for a local [azurite](https://github.com/Azure/Azurite) instance in your kubernetes cluster and the default azurite connection string. | Optionally override this with an actual Azure Storage connection string that has access to Azure Queue Storage. |


2.  SMB Listener Helm Chart [values.yaml](./smb-listener/values.yaml)

| Parameter                   | Description                        | Default Value                                                                                                                                                                  | Available values                                                                                                |
|-----------------------------|------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| `azure.aqsConnectionString` | An Azure Storage connection string | Defaults to using the connection string for a local [azurite](https://github.com/Azure/Azurite) instance in your kubernetes cluster and the default azurite connection string. | Optionally override this with an actual Azure Storage connection string that has access to Azure Queue Storage. |

3. GenAI Toolkit UI deployment [ui.yaml](charts/genai-toolkit/templates/ui.yaml)

| Environment Variable              | Description                        | Default Value                                                                                                                                                                  | Available values                                                                                                |
|-----------------------------------|------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| `AZURE_STORAGE_CONNECTION_STRING` | An Azure Storage connection string | Defaults to using the connection string for a local [azurite](https://github.com/Azure/Azurite) instance in your kubernetes cluster and the default azurite connection string. | Optionally override this with an actual Azure Storage connection string that has access to Azure Queue Storage. |


## Screenshots (on Azure)
![Services](images/services.png)
![Search](images/search.png)
![Save Smart Prompt](images/savesmartprompt.png)
![Image Generation](images/image-generation.png)
![API](images/api.png)
![Datasets and subscriptions](images/datasets.png)



## Changelog

v0.8.1:

- Minor fixes

v0.8.0:

- Added chat capabilities to FileBrowser and improved dataset embedding workflows.
- Introduced claims-based authentication and authorization features.
- Enhanced local development setup with new configurations and tools.
- Resolved issues with UI freezes, dataset embedding, and socket connection errors.
- Fixed health check API log spam and improved AWS setup reliability.
- Refactored dataset database structure and optimized justfile commands.
- Updated third-party dependencies and improved event logging.
- Updated documentation with new workflows and synced changes to the NetApp organization repository.
- Made swagger security schemes global and added detailed claims descriptions.
- Improved Kubernetes and EKS setup scripts.
- Added support for running in local/NATS mode and refined secrets management..

v0.7.0:
- Fixed multiple bugs, including token logout issues, local development paths, clustering slowness, and UI build failures.
- Added support for Claude3, Anthropic API integration, and bearer tokens in the Tool Manager.
- Improved performance with enhanced multithreading, retry logic, and faster document embedding.
- Updated build and configuration systems, including removing Poetry dependencies and adding run profiles for local vs Kubernetes setups.
0 Enhanced UI clarity, logging, and documentation for end-to-end tests and local setups.
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
