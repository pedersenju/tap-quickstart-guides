# Prerequisites for installing Tanzu Application Platform on EKS

## Credentials

* [Tanzu Network](https://network.tanzu.vmware.com/)
* [VMware Marketplace](https://marketplace.cloud.vmware.com/)

## Accept EULAs

* Sign in to [VMware Tanzu Network](https://network.tanzu.vmware.com/).
* Accept or confirm that you have accepted the EULAs for each of the following:
    * [Tanzu Application Platform](https://network.tanzu.vmware.com/products/tanzu-application-platform/)
    * [Cluster Essentials for VMware Tanzu](https://network.tanzu.vmware.com/products/tanzu-cluster-essentials/)

## Infrastructure

### EKS

* EKS cluster running 1.22 or later
* If you are using EKS 1.23 or later make sure to enable the EBS CSI add-on and provide it proper permissions to create EBS volumes. [docs here](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)

#### TAP Full, View, Build, Run, or Iterate Profile Installs

* 8 GB of RAM available per node to Tanzu Application Platform.
* 16 vCPUs available across all nodes to Tanzu Application Platform.(ex. 4 x t3.xlarge)
* 100 GB of disk space available per node.
* [Tanzu Cluster Essentials](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.3/cluster-essentials/GUID-deploy.html) installed on the cluster.
    * Download package from Tanzu Network
    * Run the following (on Mac or Linux)
    ```
    mkdir $HOME/tanzu-cluster-essentials
    tar -xvf DOWNLOADED-CLUSTER-ESSENTIALS-BUNDLE -C $HOME/tanzu-cluster-essentials
    ```
    * target cluster with kubectl
    * Run the following:
    ```
    kubectl create namespace kapp-controller
    ```

    * If your container registry requires a custom certificate to trust it run the following command to create a kapp controller config with the CA cert.

    ```
    kubectl create secret generic kapp-controller-config \
   --namespace kapp-controller \
   --from-file caCerts=ca.crt
   ```
   * Run the following where TANZU-NET-USER and TANZU-NET-PASSWORD are your credentials for VMware Tanzu Network (on Mac or Linux)
   ```
   export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle:TAP-VERSION
   export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
   export INSTALL_REGISTRY_USERNAME=TANZU-NET-USER
   export INSTALL_REGISTRY_PASSWORD=TANZU-NET-PASSWORD
   cd $HOME/tanzu-cluster-essentials
   ./install.sh --yes
   ```



### Container Registry

* A container image registry, such as Harbor or Docker Hub for application images, base images, and runtime dependencies. When available, VMware recommends using a paid registry account to avoid potential rate-limiting associated with some free registry offerings.
  * 10 GB of available storage
* Registry credentials with read and write access available to Tanzu Application Platform to store images.

### DNS

* Define a shared ingress domain. Example: `tapdomain.companydomain.com`. See [Access with the shared ingress method](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-tap-gui-accessing-tap-gui.html#ingress-method) for more information about tanzu-system-ingress. This will need to be added to DNS after we install TAP since that will create the load balancer we need and provide the IP address. In this case we just need to ensure that these DNS requirements can be met. 
* Allocate a fully Qualified Domain Name (FQDN) for TAP: `*.tapdomain.companydomain.com` 

## TAP GUI

* Git repository for TAP GUI’s software catalogs, with a token allowing read access.
    * GitHub, GitLab and Azure DevOps supported
* TAP GUI Blank Catalog from the Tanzu Application section of VMware Tanzu Network.
    * To install, navigate to the [VMware Tanzu Network](https://network.tanzu.vmware.com/products/tanzu-application-platform/#/releases/1182301). Under the list of available files to download, there is a folder titled tap-gui-catalogs-latest. Inside that folder is a compressed archive titled Tanzu Application Platform GUI Blank Catalog. You must extract that catalog to the preceding Git repository of choice. This serves as the configuration location for your organization’s catalog inside Tanzu Application Platform GUI.

## CLIs

* The Kubernetes CLI, kubectl, v1.22, v1.23 or v1.24, installed and authenticated with admin rights for your target cluster.
* [Tanzu CLI](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-install-tanzu-cli.html#install-or-update-the-tanzu-cli-and-plugins-3) and TAP Plugins
    * Download current [Tanzu CLI package from Tanzu Network](https://network.pivotal.io/products/tanzu-application-platform/#/releases/1182301/file_groups/9872) for your platform.
    * Run the following - the file names here are for mac, you will need to update this if you are using linux or windows.
    ```
    mkdir -p $HOME/tanzu
    tar -xvf tanzu-framework-darwin-amd64.tar -C $HOME/tanzu

    export TANZU_CLI_NO_INIT=true

    cd $HOME/tanzu
    export VERSION=v0.25.0
    install cli/core/$VERSION/tanzu-core-darwin_amd64 /usr/local/bin/tanzu

    tanzu plugin install --local cli all
    ```
    * Verify Tanzu CLI version by running `tanzu version`

* [kapp and imgpkg](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.3/cluster-essentials/GUID-deploy.html#optionally-install-clis-onto-your-path-6) CLIs
    * kapp and imgpkg CLIs are included in the Tanzu Cluster Essentials download above
    * Run the following
    ```
    sudo cp $HOME/tanzu-cluster-essentials/kapp /usr/local/bin/kapp

    sudo cp $HOME/tanzu-cluster-essentials/imgpkg /usr/local/bin/imgpkg
    ```

## Relocate TAP Packages to Registry

Install Docker if it is not already installed.
Log in to your image registry by running:
```
docker login MY-REGISTRY
```
Log in to the VMware Tanzu Network registry with your VMware Tanzu Network
credentials by running:
```
docker login registry.tanzu.vmware.com
```
Set up environment variables for installation use by running:
```
export INSTALL_REGISTRY_USERNAME=MY-REGISTRY-USER
export INSTALL_REGISTRY_PASSWORD=MY-REGISTRY-PASSWORD
export INSTALL_REGISTRY_HOSTNAME=MY-REGISTRY
export TAP_VERSION=VERSION-NUMBER
export INSTALL_REPO=TARGET-REPOSITORY
```
Where:

* `MY-REGISTRY-USER` is the user with write access to `MY-REGISTRY`.

* `MY-REGISTRY-PASSWORD` is the password for `MY-REGISTRY-USER`.

* `MY-REGISTRY` is your own container registry.

* `VERSION-NUMBER` is your Tanzu Application Platform version. For example, 1.3.2.

* `TARGET-REPOSITORY` is your target repository, a folder/repository on `MY-REGISTRY` that serves as the location for the installation files for Tanzu Application Platform.

Relocate the images with the imgpkg CLI by running:

    imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} --to-repo ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tap-packages
Create a namespace called tap-install for deploying any component packages by running:

    kubectl create ns tap-install
This namespace keeps the objects grouped together logically.

Create a registry secret by running:

    tanzu secret registry add tap-registry \
      --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} \
      --server ${INSTALL_REGISTRY_HOSTNAME} \
      --export-to-all-namespaces --yes --namespace tap-install
Add the Tanzu Application Platform package repository to the cluster by running:

    tanzu package repository add tanzu-tap-repository \
      --url ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}/tap-packages:$TAP_VERSION \
      --namespace tap-install
Get the status of the Tanzu Application Platform package repository, and ensure the status updates to Reconcile succeeded by running:

    tanzu package repository get tanzu-tap-repository --namespace tap-install
For example:
```
$ tanzu package repository get tanzu-tap-repository --namespace tap-install
- Retrieving repository tap...
NAME:          tanzu-tap-repository
VERSION:       16253001
REPOSITORY:    tapmdc.azurecr.io/mdc/1.0.2/tap-packages
TAG:           1.3.0
STATUS:        Reconcile succeeded
REASON:
```
List the available packages by running:

    tanzu package available list --namespace tap-install
For Example:
```
$ tanzu package available list --namespace tap-install
/ Retrieving available packages...
  NAME                                                 DISPLAY-NAME                                                              SHORT-DESCRIPTION
  accelerator.apps.tanzu.vmware.com                    Application Accelerator for VMware Tanzu                                  Used to create new projects and configurations.
  api-portal.tanzu.vmware.com                          API portal                                                                A unified user interface for API discovery and exploration at scale.
  apis.apps.tanzu.vmware.com                           API Auto Registration for VMware Tanzu                                    A TAP component to automatically register API exposing workloads as API entities
                                                                                                                                 in TAP GUI.
  backend.appliveview.tanzu.vmware.com                 Application Live View for VMware Tanzu                                    App for monitoring and troubleshooting running apps
  build.appliveview.tanzu.vmware.com                   Application Live View Conventions for VMware Tanzu                        Application Live View convention server
  buildservice.tanzu.vmware.com                        Tanzu Build Service                                                       Tanzu Build Service enables the building and automation of containerized
                                                                                                                                 software workflows securely and at scale.
  carbonblack.scanning.apps.tanzu.vmware.com           VMware Carbon Black for Supply Chain Security Tools - Scan                Default scan templates using VMware Carbon Black
  cartographer.tanzu.vmware.com                        Cartographer                                                              Kubernetes native Supply Chain Choreographer.
  cnrs.tanzu.vmware.com                                Cloud Native Runtimes                                                     Cloud Native Runtimes is a serverless runtime based on Knative
  connector.appliveview.tanzu.vmware.com               Application Live View Connector for VMware Tanzu                          App for discovering and registering running apps
  controller.conventions.apps.tanzu.vmware.com         Convention Service for VMware Tanzu                                       Convention Service enables app operators to consistently apply desired runtime
                                                                                                                                 configurations to fleets of workloads.
  controller.source.apps.tanzu.vmware.com              Tanzu Source Controller                                                   Tanzu Source Controller enables workload create/update from source code.
  conventions.appliveview.tanzu.vmware.com             Application Live View Conventions for VMware Tanzu                        Application Live View convention server
  developer-conventions.tanzu.vmware.com               Tanzu App Platform Developer Conventions                                  Developer Conventions
  eventing.tanzu.vmware.com                            Eventing                                                                  Eventing is an event-driven architecture platform based on Knative Eventing
  fluxcd.source.controller.tanzu.vmware.com            Flux Source Controller                                                    The source-controller is a Kubernetes operator, specialised in artifacts
                                                                                                                                 acquisition from external sources such as Git, Helm repositories and S3 buckets.
  grype.scanning.apps.tanzu.vmware.com                 Grype for Supply Chain Security Tools - Scan                              Default scan templates using Anchore Grype
  image-policy-webhook.signing.apps.tanzu.vmware.com   Image Policy Webhook                                                      Image Policy Webhook enables defining of a policy to restrict unsigned container
                                                                                                                                 images.
  learningcenter.tanzu.vmware.com                      Learning Center for Tanzu Application Platform                            Guided technical workshops
  metadata-store.apps.tanzu.vmware.com                 Supply Chain Security Tools - Store                                       Post SBoMs and query for image, package, and vulnerability metadata.
  ootb-delivery-basic.tanzu.vmware.com                 Tanzu App Platform Out of The Box Delivery Basic                          Out of The Box Delivery Basic.
  ootb-supply-chain-basic.tanzu.vmware.com             Tanzu App Platform Out of The Box Supply Chain Basic                      Out of The Box Supply Chain Basic.
  ootb-supply-chain-testing-scanning.tanzu.vmware.com  Tanzu App Platform Out of The Box Supply Chain with Testing and Scanning  Out of The Box Supply Chain with Testing and Scanning.
  ootb-supply-chain-testing.tanzu.vmware.com           Tanzu App Platform Out of The Box Supply Chain with Testing               Out of The Box Supply Chain with Testing.
  ootb-templates.tanzu.vmware.com                      Tanzu App Platform Out of The Box Templates                               Out of The Box Templates.
  policy.apps.tanzu.vmware.com                         Supply Chain Security Tools - Policy Controller                           Policy Controller enables defining of a policy to restrict unsigned container
                                                                                                                                 images.
  scanning.apps.tanzu.vmware.com                       Supply Chain Security Tools - Scan                                        Scan for vulnerabilities and enforce policies directly within Kubernetes native
                                                                                                                                 Supply Chains.
  service-bindings.labs.vmware.com                     Service Bindings for Kubernetes                                           Service Bindings for Kubernetes implements the Service Binding Specification.
  services-toolkit.tanzu.vmware.com                    Services Toolkit                                                          The Services Toolkit enables the management, lifecycle, discoverability and
                                                                                                                                 connectivity of Service Resources (databases, message queues, DNS records,
                                                                                                                                 etc.).
  snyk.scanning.apps.tanzu.vmware.com                  Snyk for Supply Chain Security Tools - Scan                               Default scan templates using Snyk
  spring-boot-conventions.tanzu.vmware.com             Tanzu Spring Boot Conventions Server                                      Default Spring Boot convention server.
  sso.apps.tanzu.vmware.com                            AppSSO                                                                    Application Single Sign-On for Tanzu
  tap-auth.tanzu.vmware.com                            Default roles for Tanzu Application Platform                              Default roles for Tanzu Application Platform
  tap-gui.tanzu.vmware.com                             Tanzu Application Platform GUI                                            web app graphical user interface for Tanzu Application Platform
  tap-telemetry.tanzu.vmware.com                       Telemetry Collector for Tanzu Application Platform                        Tanzu Application Plaform Telemetry
  tap.tanzu.vmware.com                                 Tanzu Application Platform                                                Package to install a set of TAP components to get you started based on your use
                                                                                                                                 case.
  tekton.tanzu.vmware.com                              Tekton Pipelines                                                          Tekton Pipelines is a framework for creating CI/CD systems.
  workshops.learningcenter.tanzu.vmware.com            Workshop Building Tutorial                                                Workshop Building Tutorial
  ```
