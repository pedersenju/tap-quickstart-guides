# Manual installation instructions for a multi-cluster footprint of Tanzu Application Platform

:mega: _Manifests included here are meant to be used as a starting point.  Limited configuration options exist.  Additional steps and updates may be required to achieve a functional installation._


## Prerequisites

### Accept EULAS

See https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/install-tanzu-cli.html.  You must accept End User License Agreements.

### Credentials

* Container image registry (host, username, password)
* .kube/config for each cluster

### Container image registry

* Tanzu Application Platform image/packages have been [relocated](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/install-air-gap.html#relocate-images-to-a-registry-0) to your desired container image registry (e.g., Harbor)

### CLIs

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) - recommend version 1.24.9 or better
* [ytt](https://carvel.dev/ytt/docs/latest/install/) - recommend v0.44.0 or better
* [tanzu](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-install-cli.html#install-the-tanzu-cli-1) - recommend 1.6.1 or better
 * [appropriate TAP plugins](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/cli-plugins-tanzu-cli.html#install-new-plugins-4) have been installed too

### Cluster

* [Cluster Essentials](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.4/cluster-essentials/deploy.html) (kapp-controller and secretgen-controller) is installed and running in cluster
  * If you're targeting TKG clusters these controllers are already installed
* Tanzu Application Platform [package repository has been installed](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/install.html#add-the-tanzu-application-platform-package-repository-1)
* Container image credentials stored as k8s Secret on cluster named `container-registry-credentials`
  * in install namespace (see tap.namespace in config.yaml)
  * in developer namespace (see tap.devNamespace in config.yaml)


### Configuration

copy the two configuration template files and then edit them with the appropriate values:

* `config-template.yaml` file within this directory so that it is representative of your environment's unique configuration (should not include sensitive data)
* `secrets-template.yaml` file, sensitive data like credentials are maintained here

```bash
cp config-template.yaml config.yaml
cp secrets-template.yaml secrets.yaml
```

## Target a cluster

```bash
kubectl config get-contexts
kubectl config use-context {context-name}
```
> Replace `{context-name}` above with context name of an (existing) cluster.

## Pre-install(Build Cluster Only)

Create developer namespace.

```bash
kubectl create namespace development
```
> The name of the namespace above should match the tap.devNamespace value in config.yaml

## Install

You will want to use the `ytt` CLI to populate a templated manifest with values from configuration and secrets values. Then you'll use the `tanzu` CLI invoking `package install` with appropriate arguments to install a specific TAP profile.

For example

```bash
ytt -f tap-template-{profile}.yaml -f config.yaml -f secrets.yaml > tap-values-{profile}.yaml
tanzu package install tap -p tap.tanzu.vmware.com -v 1.4.0 --values-file tap-values-{profile}.yaml -n tap-install
```
> Replace `{profile}` above with one of: `full`, `build`, `iterate`, `view`, `run`.

### DNS

There will be a few DNs entries that need to be created. Since this is a guide for EKS this assumes route 53. This will also assume a standard naming convention that is implemented in the templates to make record creation easier An example of naming conventions is provided below.

Base domain: mycompany.com
TAP base domain: tap.mycompany.com
TAP view domain: view.tap.mycompany.com
TAP apps domain: apps.tap.mycompany.com

**View cluster:**

Retrieve the load balancer's hostname.

```bash
kubectl get service -n tanzu-system-ingress envoy --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Create a CNAME entry for the above hostname under `*.view.tap.mycompany.com` this will allow for all domains on the view cluster to resolve and route properly.


## Update

For updates, you will follow a similar procedure. Note however that you'll invoke the `tanzu` CLI with `package installed update`.

```bash
ytt -f tap-template-{profile}.yaml -f config.yaml -f secrets.yaml > tap-values-{profile}.yaml
tanzu package installed update tap -v 1.4.0 --values-file tap-values-{profile}.yaml -n tap-install
```
> Replace `{profile}` above with one of: `full`, `build`, `iterate`, `view`, `run`.


## Verify

```
tanzu package installed list -A
```

## Post-install

You will need to perform 2 steps after completing installation of all of the following TAP profiles

* build
* iterate
* view
* run

### Authorizing access to the metadata-store

Run the script provided.

```bash
./prepare-metadata-store-secrets.sh {base64-encoded-kubeconfig-contents-of-tap-view-cluster} {base64-encoded-kubeconfig-contents-of-tap-build-cluster}
```

### Onboarding clusters to App Live View

The cluster with the TAP `view` profile installed needs to be made aware of other TAP profiles installed on clusters participating in the multi-cluster footprint.

Please follow the documented procedure [here](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/tap-gui-cluster-view-setup.html) capturing the necessary details for each cluster to then add to the [secrets.yaml](secrets.yaml) file - see lines 36-72.


## Uninstall

To uninstall, you will simply invoke

```bash
tanzu package installed delete tap -n tap-install
```
