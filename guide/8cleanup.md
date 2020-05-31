### Cleanup

In order to delete the resources created during this workshop, run the commands below:   

```
kubectl delete --all svc --namespace=nginx-ingress
kubectl delete --all svc --namespace=default
cd terraform
terraform destroy
```

&nbsp;&nbsp;

## Feedback

The code in this repo is under constant development.  

For any feedback or suggestions, either open an [Issue](https://github.com/sorinboia/nginx-experience-azure/issues) on GitHub, or contact:  

[Sorin](https://il.linkedin.com/in/sorin-boiangiu-38196938) for any NGINX related topics  

