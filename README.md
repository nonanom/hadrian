# A quest in the clouds
# My Solution

This repository contains the source code for a Node.js application, along with a Dockerfile and some GitHub Actions workflows for deployment to GCP/AWS using Terraform.

## Repository Structure

- `src/`: Application source code
- `src/Dockerfile`: Container definition for the application
- `terraform/`: Terraform configuration files for infrastructure
- `.github/workflows/`: GitHub Actions workflow definitions

## Dependencies

- Docker
- Terraform
- GCP or AWS account (depending on deployment target)

## Local Run

1. Run the Docker container image:
```bash
docker run -p 3000:3000 --platform linux/amd64 nonanom/quest:latest
```

2. Access the application: `http://localhost:3000`

Docker container image: [nonanom/quest:latest](https://hub.docker.com/repository/docker/nonanom/quest/general)



## Cloud Deployment

This project uses GitHub Actions for CI/CD. The workflows are idempotent and triggered manually.

### Configuration

Set up the following secrets and variables in your GitHub repository:

| Type | Key | Description |
|------|-----|-------------|
| Secret | APP_SECRET_WORD | Secret word for the application |
| Secret | AWS_ACCESS_KEY | AWS access key for authentication |
| Secret | AWS_ACCESS_KEY_ID | AWS access key ID |
| Secret | AWS_SECRET_ACCESS_KEY | AWS secret access key for authentication |
| Secret | DCKR_PAT | Docker personal access token |
| Secret | DCKR_USERNAME | Docker username |
| Secret | GOOGLE_APPLICATION_CREDENTIALS | Google application credentials json |
| Variable | APP_IMAGE | Docker image for the application |
| Variable | APP_NAME | Name of the application |
| Variable | APP_PORT | Port on which the application runs |

## CI/CD Workflows
The following workflows are available:

- `build-and-push-docker-image.yml`: Builds the Docker image and pushes it to Docker Hub.
- `deploy-app-to-aws.yml`: Deploys the application to AWS.
- `deploy-app-to-gcp.yml`: Deploys the application to Google Cloud Platform.
- `teardown-everything-on-aws.yml`: Removes all resources from AWS.
- `teardown-everything-on-gcp.yml`: Removes all resources from Google Cloud Platform.

These workflows automate the process of building, deploying, and managing the application infrastructure on both AWS and GCP.

# AWS
"One or more screenshots showing, at least, the index page of the final deployment in one or more public cloud(s) you have chosen."

| Check | Name |
|-------|------|
| ✅ | Running on public cloud |
| ✅ | Running in a Docker container |
| ✅ | $SECRET_WORD in app environment |
| ✅ | Running behind a load balancer |
| ✅ | Running on https |

![Alt text](https://i.imgur.com/229UcOS.png)
https://quest-1917494409.us-east-1.elb.amazonaws.com

# GCP 
"One or more screenshots showing, at least, the index page of the final deployment in one or more public cloud(s) you have chosen."

| Check | Name |
|-------|------|
| ✅ | Running on public cloud |
| ✅ | Running in a Docker container |
| ✅ | $SECRET_WORD in app environment |
| ✅ | Running behind a load balancer |
| ✅ | Running on https |

![Alt text](https://i.imgur.com/3nx04Ks.png)
https://34.54.229.232.nip.io




# Given more time, I would improve...
1. Add Microsoft Azure as a public cloud host; Run on Azure Container Instances; `terraform/azure/...`
1. Reconsider how secrets and variables are declared and used.
1. Reconsider how terraform configs are factored.
1. Provide simple terraform instructions for deploying without GitHub Actions
1. Review for parallelism/parallel structure throughout; consider conventions used for backend bucket naming.
1. Improve the README.md
1. Ask the author how the various binaries work to detect fail/pass conditions, particularly the Docker runtime.

## Author
[Mike Vincent](mailto:mike@example.com)