# NetApp's GenAI Toolkit

A self-managed cloud native solution with an easy to use UI and API to get started with GenAI, RAG workflows, Chatbots and AI assistants building with unstructured data on Azure NetApp Files or Google Cloud NetApp Volumes. Use it standalone (it has a great UI) or as a component in custom workflows via its API.

## Table of Contents
1. [Requirements](#requirements)
2. [Provides](#provides)
3. [Screenshots](#screenshots)
4. [Deploying the Toolkit](#deploying-the-toolkit)
  - [Getting Started](#getting-started)
  - [Helm Parameters](#helm-parameters)
    - [Required Parameters](#required-parameters)
    - [Optional Parameters](#optional-parameters)
5. [Changelog](#changelog)
6. [Support](#support)

## Requirements
To deploy the GenAI Toolkit, ensure that the NFS volume is accessible from the Kubernetes cluster's network. For example, if you are using Azure NetApp Files (ANF) and Azure Kubernetes Service (AKS), both should be on the same virtual network (vNet) or the vNets should be peered.

## Provides
- Enterprise level Document Search through LLM vector embeddings (auto embeds with built in PGVector DB)
- Chatbot (RAG) UI/API
- Tooling for Chatbots
- RAG model evaluations
- Exportable Smart Prompts/Chatbot endpoints
- (Assistants/Agents TBD)

## Screenshots (on Azure)
![Services](images/services.png)
![Search](images/search.png)
![Save Smart Prompt](images/savesmartprompt.png)
![Image Generation](images/image-generation.png)
![API](images/api.png)

## Deploying the Toolkit

The toolkit is a set of kubernetes yamls, wrapped up in helm charts that can be installed on any cluster using helm.

### Getting Started
From the root directory of the repository, just run:

```sh
helm install genai-toolkit genai-toolkit-helmcharts --set cloudProvider="anf",nfs.server_ip="1.2.3.4",nfs.path="my-directory"
```

### Helm Parameters

#### Required Parameters

| Parameter       | Description                            | Default Value |
|-----------------|----------------------------------------|---------------|
| `nfs.server_ip` | IP address of the NFS server.          | None          |
| `nfs.path`      | Path on the NFS server.                | None          |

#### Optional Parameters

| Parameter             | Description                              | Default Value | Available values |
|-----------------------|------------------------------------------|---------------|------------------|
| `cloudProvider`       | Specifies the cloud provider to use.     | `anf`         | `anf` / `gcnv`   |
| `db.connectionString` | Specifies the database connection string | None          |

Note: By not setting the `db.connectionString` the toolkit will default to use an in cluster database. This is not recommended for production use cases. For testing, it is fine.

There are other optional variables but these are only used for development of the toolkit and do not require any attention.

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
