# Datadrivers Testaufgabe #

This is quite frankly pretty minimal effort. But EKS was new to me and I didn't feel like going too deep that rabbit hole.

## The app ##
Really minimalist Express app that prints hello world

## Docker ##

I hate how the app is built. The determinism of the build is a joke. But I didn't want to waste too much time making it nice with Nix.

If it's good enough for industry practice it's  good enough for this. :D

## EKS and ECR ## 
Amazon resrources are deployed via Terraform. Terraform uses a s3 bucket as storage location so that it has the state in a central location. Otherwise deployment via pipeline would be very problematic.

The EKS code is 100% lifted from  https://github.com/hashicorp-education/learn-terraform-provision-eks-cluster and https://developer.hashicorp.com/terraform/tutorials/aws/eks
I EKS is new to me, I didn't want to spend my time finding out the basiscs.

## Kubernetes ##
I didn't use Helm or anything fancy. Just a bunch of hardcoded yaml files. I dislike Helm for basically being a text templating engine that's being used for data manipulation anyway.
I guess if I had a need for customisations Kustomize is the reasonable choice. Or Cue.

## Ingress ##
EKS clusters don't have a default Ingress Controller. ALB looks like a good choice, but deploying that looked awful. 

I'm using a `LoadBalancer` now, ELB are expensive and kind of dumb. But it works out of the box.

## Pipeline ##
Pretty much minimal low effort I admit. But it gets the job done. Merge in the `stable` branch and stuff gets deployed. All other git refs only run the test steps.

This is whre I see the most improvements.

First of all, again all the tooling is non deterministic. I did use Nix a bit but it was slowing me down.
This isn't the kind of project that will break if tools upate, but it feels dirty.

The biggest missing feature is staging. Right now there is only one instance of the cluster and the application and that is in the `stable` branch.
Better would be a structure like `deploy/test`, `deploy/stage`, `deploy/release` or something like that. All with their own deployment.

There is no test of the deployed cluster and app.

