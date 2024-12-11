# Datadrivers Test Task #

This repository showcases a minimal example project. While the implementation is intentionally kept simple, it demonstrates my approach to exploring new technologies—specifically, Amazon EKS.


[![dev](https://github.com/tbaumann/datadriver-testaufgabe/actions/workflows/deploy.yaml/badge.svg?branch=releases%2Fdev)](https://github.com/tbaumann/datadriver-testaufgabe/actions/workflows/deploy.yaml)
[![prod](https://github.com/tbaumann/datadriver-testaufgabe/actions/workflows/deploy.yaml/badge.svg?branch=releases%2Fprod)](https://github.com/tbaumann/datadriver-testaufgabe/actions/workflows/deploy.yaml)

## The App ##

The application is a minimalist Express.js app that responds with "Hello, World."  

- **Configuration**: The app reads `name` and `port` values from a ConfigMap mounted at `/config`. The ConfigMap can be updated at runtime to adjust the app's behavior without redeployment.  
- **Endpoints**:  
  - `/ready`: Simulates a slow startup, which is useful for readiness probes.  
  - `/live`: Always returname `HTTP: 200`
  - `/`: Greets back `name` 

## Docker ##

The App and the Image is built with Nix. The docker image with `dockerTools.buildLayeredImage` which builds a compact layered docker image with a high likelyhoood of layers being reusable.

## EKS and ECR ## 

AWS resources are provisioned using Terraform:  
- **State Management**: Terraform uses an S3 bucket for storing the state, enabling centralized state management and pipeline-friendly deployments.  
- **Cluster Setup**: The EKS Terraform configuration is entirely stolen from [Learn Terraform - Provision an EKS Cluster](https://github.com/hashicorp-education/learn-terraform-provision-eks-cluster) [Terraform EKS Tutorial](https://developer.hashicorp.com/terraform/tutorials/aws/eks)  

EKS was new to me, so I focused on gettint it work instead of full comprehension. As anything AWS the complexity is horrendeus.

## Kubernetes ##

For Kubernetes manifests:  
- I used plain YAML files without tools like Helm, as I find Helm's templating approach too text-oriented for structured data manipulation.  
- If customizations were needed, tools like Kustomize or Cue would be my preferred alternatives.
- I just use `envsubst` to replace the image name in the deployment.

## Ingress ##

EKS clusters do not include a default Ingress Controller:  
- **Options Considered**:  
  - ALB is an obvious choice. But it was far from straight forward to deploy.
  - I opted for a `LoadBalancer` service. While Elastic Load Balancers (ELBs) can be expensive and rudimentary, this setup works out of the box for this example.  

## Pipeline ##

The CI/CD pipeline is minimal but functional:  
- **Workflow**:  
  - Merging to the `release/dev` branch triggers deployment to the dev cluster.  
  - Merging to the `release/prod` branch triggers deployment to the prod cluster.  
  - Other branches and git references run tests only.  

Run the pipeline locally with 
```shell
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
nix develop --command ci-local -d -s dev
# -d enables deploy mode. Default is just test.
# If -s is omitted the git revision is used
```

## Nix Shell ##

Run `nix develop` to get a shell with all corret tools installed.

`nix flake update` to update pinned package versions.


Build outputs for the image and the app are provided by the flake.

```shell
# Build app
nix build .#default # Builds a wrapper called result/bin/datadrivers-demo-app

#run app 
mkdir ./conf 
export KUBERNETES_CONFIG_MOUNT_PATH=./conf
nix run 
#or 
nix run github.com:tbaumann/datadriver-testaufgabe

#Build docker
nix build .#docker
docker load -i result
```

### Potential Improvements ###

1. **End-to-End Tests**:  
   - Currently, there are no tests for the deployed cluster or application. If it deploys it works. 
   - Adding automated tests for the deployment and application behavior would increase confidence in the pipeline.  (Especially with staging)

---

### Why This Approach? ###

This project prioritizes practicality and speed over perfection. By focusing on the essentials, I could experiment with EKS and set up a working example without getting lost in excessive complexity.  

## Sparse git log ##
I had to rebase my history a bit because I accidentally committed my `.envrc` with the AWS keys.
