## Security

In our final part of the workshop, we will implement a per-pod Web Application Firewall.  
The Nginx WAF will allow to improve the application security posture, especially against [OWASP Top 10 attacks](https://owasp.org/www-project-top-ten/).  

In our scenario, since we decided our Nginx WAF to be enabled on a per-pod basis, we will be able to protect all the traffic coming into the pod regardless of where it is originating from (external or internal to the Kubernetes cluster).  

We'll be able to bring security closer to the application and the development cycle and integrate it into CI/CD pipelines.  
This will allow to minimize false positives, since the WAF policy becomes a part of the application and is always tested as such.  

1. Create the Nginx WAF config, which can be found in the "files/7waf/waf-config.yaml" file.  

<pre>
Command:
kubectl apply -f files/7waf/waf-config.yaml
</pre>

The WAF policy is json based and from the example bellow, you can observe how all the configuration can be changed based on the application needs:  
<pre>
    {
      "name": "nginx-policy",
      "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
      "applicationLanguage": "utf-8",
      "enforcementMode": "blocking",
      "signature-sets": [
      {
          "name": "All Signatures",
          "block": false,
          "alarm": true
      },
      {
          "name": "High Accuracy Signatures",
          "block": true,
          "alarm": true
      }
    ],
      "blocking-settings": {
      "violations": [
          {
              "name": "VIOL_RATING_NEED_EXAMINATION",
              "alarm": true,
              "block": true
          },
          {
              "name": "VIOL_HTTP_PROTOCOL",
              "alarm": true,
              "block": true,
              "learn": true
          },
          {
              "name": "VIOL_FILETYPE",
              "alarm": true,
              "block": true,
              "learn": true
          },
          {
              "name": "VIOL_COOKIE_MALFORMED",
              "alarm": true,
              "block": false,
              "learn": false
          }
      ],
          "http-protocols": [{
          "description": "Body in GET or HEAD requests",
          "enabled": true,
          "learn": true,
          "maxHeaders": 20,
          "maxParams": 500
      }],
          "filetypes": [
          {
              "name": "*",
              "type": "wildcard",
              "allowed": true,
              "responseCheck": true
          }
      ],
          "data-guard": {
          "enabled": true,
              "maskData": true,
              "creditCardNumbers": true,
              "usSocialSecurityNumbers": true
      },
      "cookies": [
          {
              "name": "*",
              "type": "wildcard",
              "accessibleOnlyThroughTheHttpProtocol": true,
              "attackSignaturesCheck": true,
              "insertSameSiteAttribute": "strict"
          }
      ],
          "evasions": [{
          "description": "%u decoding",
          "enabled": true,
          "learn": false,
          "maxDecodingPasses": 2
      }]}
    }
</pre>

2. Deploy ELK in order to be able to visualize and analyze the traffic going through the Nginx WAF:  

<pre>
Command:
cat files/7waf/elk.yaml | sed "s/{{randomnumber}}/$randomnumber/g" | kubectl apply -f -
</pre>


4. Verify that ELK is up and running by browsing to: `http://elk-[RANDOM GENERATED NUMBER].uksouth.cloudapp.azure.com:5601/`.  

:warning: Please note that it might take some time for the DNS name and the ELK deployment to become available.

5. Next, we need to change our deployment configuration so it includes the Nginx WAF.
<pre>
Commands:
kubectl apply -f files/7waf/arcadia-main.yaml
kubectl apply -f files/7waf/arcadia-app2.yaml
kubectl apply -f files/7waf/arcadia-app3.yaml
kubectl apply -f files/7waf/arcadia-backend.yaml
</pre>

All of our services are protected and monitored.

6. Browse again to the Arcadia web app and verify that it is still working.  

7. Let's simulate a Cross Site Scripting (XSS) attack, and make sure it's blocked:  

`https://arcadia-[RANDOM GENERATED NUMBER].uksouth.cloudapp.azure.com/trading/index.php?a=%3Cscript%3Ealert(%27xss%27)%3C/script%3E`

Each of the blocked requests will generate a support ID, save it for later.  

8. Browse to the ELK as before and click the "Discover" button:  

![](images/kibana1.JPG)  

  
  
Here, you'll see all the request logs, allowed and blocked, sent by the Nginx WAF to ELK.  

Let's look for the reason why our attack requests were blocked.  


9. Add a filter with the support ID you have received as seen bellow:
  
![](images/kibana2.JPG)  

In the right side of the panel, you can see the full request log and the reason why it was blocked.  

10. Continue and explore the visualization capabilities of Kibana and log information from Nginx WAF by looking into the next two sections bellow the "Discover" button (Visualize and Dashboard -> Overview).  

  

![](images/7env.JPG)

  

#### [Next: Cleanup](8cleanup.md)

