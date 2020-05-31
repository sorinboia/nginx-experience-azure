## Deploy NGINX infrastructure using Terraform

We will start by using Terraform to deploy the initial infrastructure which includes the Amazon Elastic Kubernetes Service and the EC2 instance for the Nginx Controller.

1. Go to the "terraform" directory where we can find the terraform plan.

<pre>
cd terraform
</pre>

2. Run the following commands, terraform plan will show us what it is going to be deployed in AWS by Terraform:
<pre>
terraform init
terraform plan
</pre>


3. Now let's deploy the environment
<pre>
terraform apply --auto-approve
</pre>


It will take around 10 minutes for Terraform and Azure to finish the initial deployment.
While you wait, you can review the [Core concepts for Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads) to learn about Kubernetes and Azure AKS basics.  


Wait for Terraform is to finish and verify the deployment is working as expected and we are able to control the Kubernetes environment.

4. We need to save the remote access config for the Kubernetes cluster locally:  
<pre>
mkdir ~/.kube/ 
terraform output kube_config > ~/.kube/config
</pre>

5. Check and see that our cluster is up an running.  
Below we should see our two K8s worker nodes:
<pre>
Command:
kubectl get nodes

Output:   
NAME                                STATUS   ROLES   AGE     VERSION
aks-agentpool-21324540-vmss000000   Ready    agent   5m19s   v1.15.10
aks-agentpool-21324540-vmss000001   Ready    agent   5m10s   v1.15.10
aks-agentpool-21324540-vmss000002   Ready    agent   5m5s    v1.15.10
</pre>

And the `kube-system` pods (this is the namespace for objects created by the Kubernetes system):  
<pre>
Command:
kubectl get pods -n kube-system

Output:
NAME                                  READY   STATUS    RESTARTS   AGE
coredns-698c77c5d7-kprwb              1/1     Running   0          5m5s
coredns-698c77c5d7-pwfdn              1/1     Running   0          8m17s
coredns-autoscaler-5bd7c6759b-msb6f   1/1     Running   0          8m14s
kube-proxy-72ws2                      1/1     Running   0          5m19s
kube-proxy-rpxxg                      1/1     Running   0          5m28s
kube-proxy-srl45                      1/1     Running   0          5m14s
metrics-server-7d654ddc8b-t889n       1/1     Running   0          8m17s
tunnelfront-698dbdbb5-k5rfx           1/1     Running   0          8m16s  
</pre>

At the moment we have our setup deployed as it can be seen in the bellow diagram.

![](images/3env.JPG)

6. Change the directory back to the original repo folder:
```
cd ..
```

Next we will move on to deploying the application.

#### [Next part](4unit.md)
