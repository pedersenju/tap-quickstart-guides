# Manual installation instructions for a multi-cluster footprint of Tanzu Application Platform

:mega: _Manifests included here are meant to be used as a starting point.  Limited configuration options exist.  Additional steps and updates may be required to achieve a functional installation._


## Prerequisites

### Credentials

* Container image registry (host, username, password)
* .kube/config for each cluster

### Container image registry

* Tanzu Application Platform image/packages have been relocated to your desired container image registry (e.g., Harbor)

### CLIs

* kubectl
* ytt
* tanzu
 * appropriate plugins have been installed too

### Cluster

* Cluster Essentials (kapp-controller and secretgen-controller) is installed and running in cluster
  * If you're targeting TKG clusters these controllers are already installed
* Tanzu Application Platform image bundles have been relocated to a repository in your container image registry
* Tanzu Application Platform repository has been installed
* Container image credentials stored as k8s Secret on cluster named container-registry-credentials
  * in install namespace (see tap.namespace in config.yaml)
  * in developer namespace (see tap.devNamespace in config.yaml)
* Contour, cert-manager, and external-dns have been configured and installed
  * ClusterIssuer installed
  * Wildcard Certificate issued and valid
  * TLSCertificateDelegation configured

### Configuration

Open, edit and save values in:

* `config.yaml` file within this directory so that it is representative of your environment's unique configuration (should not include sensitive data)
* `secrets.yaml` file, sensitive data like credentials are maintained here


## Target a cluster

```bash
kubectl config get-contexts
kubectl config use-context {context-name}
```
> Replace `{context-name}` above with context name of an (existing) cluster.


## Install

You will want to use the `ytt` CLI to populate a templated manifest with values from configuration and secrets values. Then you'll use the `tanzu` CLI invoking `package install` with appropriate arguments to install a specific TAP profile.

For example

```bash
ytt -f tap-template-{profile}.yaml -f config.yaml -f secrets.yaml > tap-values-{profile}.yaml
tanzu package install tap -p tap.tanzu.vmware.com -v 1.4.0 --values-file tap-values-{profile}.yaml -n tap-install
```
> Replace `{profile}` above with one of: `full`, `build`, `iterate`, `view`, `run`.


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

## Uninstall

To uninstall, you will simply invoke

```bash
tanzu package installed delete tap -n tap-install
```
