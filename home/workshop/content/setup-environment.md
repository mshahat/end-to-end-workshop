## Welcome to a Hands On Lab on VMware Tanzu!  In this session, we are going to explore some of the [Tanzu Advanced Edition](https://tanzu.vmware.com/tanzu/advanced "Tanzu Advanced Edition") capabilities with focus on the Developer and DevSecOps supply chain

For the **Accenture CIE** event taking place in **March 2021** we will explore 

  1. A [Spring](http://start.spring.io/ "Spring") app 
  1. [Concourse](https://tanzu.vmware.com/concoursehttp:// "Concourse") as a cloud native CI server
  1. [Tanzu Build Service](https://tanzu.vmware.com/build-service "Tanzu Build Service") as a declartive and repeatible approach to building your source code into container image see [paketo-io](https://paketo.io "paketo-io") and [kpack](https://github.com/pivotal/kpack "kpack")
  1. [Harbor](https://goharbor.io/ "Harbor") as a private container image registry
  1. [Kubeapps](https://tanzu.vmware.com/developer/guides/kubernetes/kubeapps-gs/ "Kubeapps") as a local marketplace of curated apps such as databases. That's the OSS version of [Tanzu Application Catalog](https://tanzu.vmware.com/application-catalog "Tanzu Application Catalog")
  1. [Tanzu Observability](https://tanzu.vmware.com/observability "Tanzu Observability") for showing the application and kuberenetes metrics

We're going to be using Tanzu componets to develop, build, host image and deploy an application, deploy dependent services for that application, observe the metrics for that application and supporting infrastructure, and manage the cluster hosting that application.

# Fork Spring Pet Clinic
To get started, you need to clone Spring Pet Clinic to you can make some changes to it as part of the demo process.  Click the icon in the upper right of the box below to open a new browser tab so that you can fork the Spring Pet Clinic repo into your Github account.
```dashboard:open-url
url: https://github.com/tanzu-end-to-end/spring-petclinic/fork
```
After forking, navigate to the `/src/main/resources/messages/messages.properties` file in your forked repo.  We would like you to have this tab opened so you are ready to make an edit to this file to trigger a build later on.

# Concourse
When your session was created, we logged into Concourse and added your pipeline.  Since you need to point to your fork of Spring Pet Clinic, we need to create some secrets for your Concourse pipeline.  You will need to paste the url for your PetClinic fork into the terminal prompt after clicking the box below.
```terminal:execute
command: |-
  read -p "Enter the Git URL of your fork of Pet Clinic: " PETCLINIC_GIT_URL; \
  ytt -f pipeline/secrets.yaml -f pipeline/values.yaml \
  --data-value commonSecrets.harborDomain=harbor.{{ ingress_domain }} \
  --data-value commonSecrets.kubeconfigBuildServer=$(yq d ~/.kube/config 'clusters[0].cluster.certificate-authority' | yq w - 'clusters[0].cluster.certificate-authority-data' "$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)" | yq r - -j) \
  --data-value commonSecrets.kubeconfigAppServer=$(yq d ~/.kube/config 'clusters[0].cluster.certificate-authority' | yq w - 'clusters[0].cluster.certificate-authority-data' "$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)" | yq r - -j) \
  --data-value commonSecrets.concourseHelperImage=harbor.{{ ingress_domain }}/concourse/concourse-helper \
  --data-value petclinic.wavefront.deployEventName=petclinic-deploy \
  --data-value petclinic.configRepo=https://github.com/mshahat/spring-petclinic-config \
  --data-value petclinic.host=petclinic-{{ session_namespace }}.{{ ingress_domain }} \
  --data-value petclinic.image=harbor.{{ ingress_domain }}/{{ session_namespace }}/spring-petclinic \
  --data-value petclinic.tbs.namespace={{ session_namespace }} \
  --data-value petclinic.wavefront.applicationName=petclinic-{{ session_namespace }} \
  --data-value "petclinic.codeRepo=${PETCLINIC_GIT_URL}" \
   | kubectl apply -f- -n concourse-{{ session_namespace }}
session: 1
```
The pipeline starts off paused, so let's unpause it now that we've created secrets for it.
```terminal:execute
command: fly -t concourse unpause-pipeline -p spring-petclinic
session: 1
```

Now, let's open a browser window to your pipeline.  Login with user "{{ ENV_CONCOURSE_USERNAME }}" and password "{{ ENV_CONCOURSE_PASSWORD }}"
```dashboard:open-url
url: https://concourse.{{ ingress_domain }}/teams/{{ session_namespace }}/pipelines/spring-petclinic
```
Validate that it is picking up your code and doing the first build.  It is important to let this process complete so that it can pre-cache all your dependencies and allow your builds to execute much faster.  This will take a while the first time.

# Harbor
Next, click the link below and login to Harbor with the user "admin" and password "{{ ENV_HARBOR_PASSWORD }}".  If you login and aren't redirected to your project, then simply close the Harbor tab that was opened, and reopen it with the link below.
```dashboard:open-url
url: https://harbor.{{ ingress_domain }}/harbor/projects/{{ harbor_project_id }}/repositories
```

# Spring Pet Clinic App
Open a tab to your deployed Pet Clinic instance
```dashboard:open-url
url: https://petclinic-{{ session_namespace }}.{{ ingress_domain }}
```
If you don't see the Pet Clinic interface at first, go back to your Concourse tab and ensure that the `continuous-delivery` job completed successfully.  The first build can take a few minutes to complete and deploy.

# Access Kubeapps
We'll be logging into KubeApps next.  To do that, we'll need to grab our user token to use to login.  Copy your user token below to use to login to kubeapps in the next step.
```workshop:copy
text: {{ user_token }}
```

Now, click the following link to open a new tab to Kubeapps pointing to a DB deployment that was created for you when you launched this environment. In the login screen, paste your token into the text field, and click "Login".  
```dashboard:open-url
url: https://kubeapps.{{ ingress_domain }}/#/c/default/ns/{{ session_namespace }}/apps
```
You should see a MySQL Deployment called `petclinic-db`.  It may still be starting when you first examine it, but it should go to 1 pod active fairly quickly.  Leave this view on the "Apps" tab so it is staged properly.

# SaaS Services

VMware Tanzu components such as Tanzu Mission Control or Tanzu Service Mesh are SaaS services. We encourage you to register for a trial on https://cloud.vmware.com and try it later. They are not part of today's Hands On Lab

```dashboard:open-url
url: https://console.cloud.vmware.com
```

## Tanzu Observability
Open a tab to Tanzu Observability for your Pet Clinic Dashboard.  First, you will need to sign in to the following Wavefront instance.
```dashboard:open-url
url: https://vmware.wavefront.com/
```

Now, copy your app name below, click on the Application dropdown and select Service Dashboard, and on the new page click on the Application dropdown and paste the app name you copied previously into the application dropdown and select the application. It may take a minute for metrics to flow in where you can actually select that application name, so if you can't see your app in the list try to refresh the page the page after a minute or two.
```workshop:copy
text: petclinic-{{ session_namespace }}
```

# Spring and/or Steeltoe Starters
Click the links below to open up to the project generators for Spring and Steeltoe for .NET
```dashboard:open-url
url: https://start.spring.io
```

```dashboard:open-url
url: https://start.steeltoe.io
```

# What has been covered
We expect you have gone through the following
* start.spring.io
* The Pet Clinic spring app running
* The GitHub repo of the Pet Clinic example app 
* Concourse
  * Make sure to go back to the pipeline overview to be staged on your "continuous-integration" and "continuous-delivery" jobs.
* Harbor
  * Make sure to refresh the list of repositories after your app is deployed so that you are staged showing the "spring-petclinic" and "spring-petclinic-source" repositories.
* Kubeapps and TAC
* TO