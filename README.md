# CS554-terraforming

This project is my submission to CS 554 Project 2: Terraform.

It involves using [Terraforming](https://developer.hashicorp.com/terraform) to create and manage small container clusters through both Docker and k8s, giving two seperate demos of cluster environments.

This README contains a reflection of this project. More documentation about the layout of the individual clusters lies within the project folders.

## Reflection

  This project helped me understand more thoroughly how Docker networks and k8s clusters work in practice. I already have experience in Docker/k8s (microk8s) through work, but it was nice to be able to start from 'sratch' and work my way up. As expected, I learned that kubernetes is much more confusing and difficult to manage, especially when your cluster is hosted through a WSL instance. Closing this instance (so my computer could relax) would break the cluster and I'd have to restart it and reconfigure everything. Docker is much more simple to use, and way better suited for a small scale project like this. Ultimately, I learned that kubernetes is just as much as a pain in the butt as I expected it to be, but it has much more potential than simply clustering together docker containers with Terraform.
