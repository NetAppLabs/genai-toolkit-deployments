# GenAI Toolkit API

Welcome to the GenAI Toolkit API! This toolkit provides a set of powerful APIs designed to help you build GenAI workflows and application grounded in your own data on Google Cloud NetApp Volumes or Azure NetApp Files. The API allows you to create and manage chat sessions with your data, export SmartPrompts (experts on topics based on your data) and evaluate LLM models and their RAG performance, and more. This README provides an overview of the API endpoints and how to get started. [Click here for swagger definition](apiv2_swagger.json)



## Table of Contents

- [Getting Started](#getting-started)
- [API Endpoints](#api-endpoints)
  - [ChatSessions](#chatsessions)
  - [Embed](#embed)
  - [Evaluations](#evaluations)
  - [ImagePrompt](#imageprompt)
  - [Keys](#keys)
  - [ModelConfiguration](#modelconfiguration)
  - [Prompt](#prompt)
  - [Questions](#questions)
  - [QuestionSets](#questionsets)
  - [RagConfiguration](#ragconfiguration)
  - [SmartPrompts](#smartprompts)
  - [User](#user)
  - [Util](#util)
- [Schemas](#schemas)
- [Contact](#contact)

## Getting Started

To start using the GenAI Toolkit API all you need to do is to register and log into the toolkit either with the built in user interface or by using the API to get your API access token. 
If using the UI just navigate to the 'Profile' page to copy your API access token. If you want to automate the process through an API follow these steps:

1. **Register**: Create a new account using the `/Register` endpoint.
2. **Login**: Authenticate your account using the `/Login` endpoint to receive an access token.
3. **Use the API!**: Once you have the (Bearer) access token you can now call all the API endpoints.

### Example

Here’s a quick example to get you started:

```bash
# Register a new user
curl -X POST "http://localhost:8001/Register" -H "Content-Type: application/json" -d '{
  "email": "user@example.com",
  "password": "yourpassword"
}'

# Login and get access token
curl -X POST "http://localhost:8001/Login" -H "Content-Type: application/json" -d '{
  "email": "user@example.com",
  "password": "yourpassword"
}'

# Use the access token to list the LLM API keys
curl -X GET "http://localhost:8001/Keys" -H "Authorization: Bearer your-access-token"
```

## API Endpoints

### ChatSessions

- **Create a Chat Session**: 
  ```http
  POST /ChatSessions
  ```
  Initiates a new chat session.

- **Get All Chat Sessions**:
  ```http
  GET /ChatSessions
  ```
  Retrieves a list of all chat sessions.

- **Get a Chat Session by ID**:
  ```http
  GET /ChatSessions/{id}
  ```
  Fetches details of a specific chat session by its ID.

- **Update a Chat Session**:
  ```http
  PATCH /ChatSessions/{id}
  ```
  Updates an existing chat session.

### Embed

- **Create an Embed Request**:
  ```http
  POST /Embed
  ```
  Initiates an embedding process for content.

- **Extract Lines**:
  ```http
  POST /Embed/extractLines
  ```
  Extracts lines from a specified file for embedding.

- **Check Embed Status**:
  ```http
  GET /Embed/status
  ```
  Retrieves the status of an embedding process.

### Evaluations

- **Get Evaluations**:
  ```http
  GET /Evaluations
  ```
  Lists all evaluations.

- **Create an Evaluation**:
  ```http
  POST /Evaluations
  ```
  Submits a new evaluation request.

- **Get Evaluation by ID**:
  ```http
  GET /Evaluations/{evaluationId}
  ```
  Fetches details of a specific evaluation by its ID.

### ImagePrompt

- **Generate an Image Prompt**:
  ```http
  GET /ImagePrompt
  ```
  Generates an image based on the provided prompt.

### Keys

- **Get API Keys**:
  ```http
  GET /Keys
  ```
  Lists all API keys.

- **Create an API Key**:
  ```http
  POST /Keys
  ```
  Creates a new API key.

- **Update an API Key**:
  ```http
  PATCH /Keys/{keyId}
  ```
  Updates an existing API key.

- **Delete an API Key**:
  ```http
  DELETE /Keys/{keyId}
  ```
  Deletes an API key.

### ModelConfiguration

- **Get Model Configurations**:
  ```http
  GET /ModelConfiguration
  ```
  Lists all model configurations.

- **Create a Model Configuration**:
  ```http
  POST /ModelConfiguration
  ```
  Creates a new model configuration.

- **Get Model Configuration by ID**:
  ```http
  GET /ModelConfiguration/{id}
  ```
  Fetches details of a specific model configuration by its ID.

- **Update a Model Configuration**:
  ```http
  PATCH /ModelConfiguration/{id}
  ```
  Updates an existing model configuration.

- **Delete a Model Configuration**:
  ```http
  DELETE /ModelConfiguration/{id}
  ```
  Deletes a model configuration.

### Prompt

- **Create a Prompt**:
  ```http
  POST /Prompt
  ```
  Submits a prompt for processing.

- **Create a Prompt by GUID**:
  ```http
  POST /Prompt/{guid}
  ```
  Submits a prompt using a specific GUID.

### Questions

- **Get Questions**:
  ```http
  GET /QuestionSets/{questionSetId}/Questions
  ```
  Lists all questions in a specified question set.

- **Create a Question**:
  ```http
  POST /QuestionSets/{questionSetId}/Questions
  ```
  Creates a new question in a specified question set.

- **Get Question by ID**:
  ```http
  GET /QuestionSets/{questionSetId}/Questions/{questionId}
  ```
  Fetches details of a specific question by its ID.

- **Update a Question**:
  ```http
  PUT /QuestionSets/{questionSetId}/Questions/{questionId}
  ```
  Updates an existing question.

- **Delete a Question**:
  ```http
  DELETE /QuestionSets/{questionSetId}/Questions/{questionId}
  ```
  Deletes a question.

### QuestionSets

- **Get Question Sets**:
  ```http
  GET /QuestionSets
  ```
  Lists all question sets.

- **Create a Question Set**:
  ```http
  POST /QuestionSets
  ```
  Creates a new question set.

- **Get Question Set by ID**:
  ```http
  GET /QuestionSets/{questionSetId}
  ```
  Fetches details of a specific question set by its ID.

- **Update a Question Set**:
  ```http
  PUT /QuestionSets/{questionSetId}
  ```
  Updates an existing question set.

- **Delete a Question Set**:
  ```http
  DELETE /QuestionSets/{questionSetId}
  ```
  Deletes a question set.

### RagConfiguration

- **Get RAG Configurations**:
  ```http
  GET /RagConfiguration
  ```
  Lists all RAG configurations.

- **Create a RAG Configuration**:
  ```http
  POST /RagConfiguration
  ```
  Creates a new RAG configuration.

- **Get RAG Configuration by ID**:
  ```http
  GET /RagConfiguration/{id}
  ```
  Fetches details of a specific RAG configuration by its ID.

- **Update a RAG Configuration**:
  ```http
  PATCH /RagConfiguration/{id}
  ```
  Updates an existing RAG configuration.

### SmartPrompts

- **Get Smart Prompts**:
  ```http
  GET /SmartPrompts
  ```
  Lists all smart prompts.

- **Create a Smart Prompt**:
  ```http
  POST /SmartPrompts
  ```
  Creates a new smart prompt.

- **Get Smart Prompt by ID**:
  ```http
  GET /SmartPrompts/{id}
  ```
  Fetches details of a specific smart prompt by its ID.

- **Update a Smart Prompt**:
  ```http
  PATCH /SmartPrompts/{id}
  ```
  Updates an existing smart prompt.

- **Delete a Smart Prompt**:
  ```http
  DELETE /SmartPrompts/{id}
  ```
  Deletes a smart prompt.

### User

- **Register User**:
  ```http
  POST /Register
  ```
  Registers a new user.

- **Login User**:
  ```http
  POST /Login
  ```
  Authenticates a user and returns an access token.

- **Get User Profile**:
  ```http
  GET /Profile
  ```
  Retrieves the profile of the authenticated user.

### Util

- **Get Directory Information**:
  ```http
  GET /Util/dir
  ```
  Retrieves information about a directory.

- **Get Volume Information**:
  ```http
  GET /Util/volumes
  ```
  Retrieves information about available volumes.

## Schemas

The GenAI Toolkit API uses JSON schemas to define the structure of the requests and responses. Detailed schema definitions are available in the API documentation.

## Contact

If you have any questions, issues, or feedback, please reach out to our support team at hinrik@netapp.com

Happy coding!

---

This document provides a brief overview of the GenAI Toolkit API. For more detailed information, please refer to the full API documentation and interactive swagger UI available at in the GenAI Toolkit application under "Profile"