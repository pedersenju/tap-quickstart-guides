# Install Tanzu Application Platform on  EKS
Assumes [prerequisites](PREREQS.md) have been fulfilled.

## Target a cluster

```bash
kubectl config get-contexts
kubectl config use-context {context-name}
```
> Replace `{context-name}` above with context name of an appropriate (existing) cluster.

## Install

### Prepare configuration

We are going to start with a minimal install and basic supply chain. This will not include scanning,testing,gitops etc. If you would like to do that please jump to [advanced install](ADVANCED_INSTALL.md)

Edit this sample configuration and save to a file named `tap-values.yml`.

```yml
ceip_policy_disclosed: true

shared:
  ingress_domain: "INGRESS-DOMAIN"
  image_registry:
    project_path: "SERVER-NAME/REPO-NAME"
    username: "KP-DEFAULT-REPO-USERNAME"
    password: "KP-DEFAULT-REPO-PASSWORD"
  ca_cert_data: | # To be passed if using custom certificates.
      -----BEGIN CERTIFICATE-----
      MIIFXzCCA0egAwIBAgIJAJYm37SFocjlMA0GCSqGSIb3DQEBDQUAMEY...
      -----END CERTIFICATE-----


# The above keys are minimum numbers of entries needed in tap-values.yaml to get a functioning TAP full profile installation.

# Below are keys which may have default values set, but can be overridden.

# Can take iterate, build, run, view.
profile: full
# Can take [ testing, testing_scanning ].
supply_chain: basic

# Based on supply_chain set above, can be changed to [ ootb_supply_chain_testing, ootb_supply_chain_testing_scanning] .
ootb_supply_chain_basic:
  registry:
    # Takes the value from shared section above by default, but can be overridden by setting a different value.
    server: "SERVER-NAME"
    # Takes the value from shared section above by default, but can be overridden by setting a different value.
    repository: "REPO-NAME"
  gitops:
    # Takes "" as value by default; but can be overridden by setting a different value.
    ssh_secret: "SSH-SECRET-KEY"

contour:
  envoy:
    service:
      # This is set by default, but can be overridden by setting a different value.
      type: LoadBalancer

buildservice:
  kp_default_repository: "KP-DEFAULT-REPO"
  kp_default_repository_username: "KP-DEFAULT-REPO-USERNAME"
  kp_default_repository_password: "KP-DEFAULT-REPO-PASSWORD"

tap_gui:
  # If the shared.ingress_domain is set as above, this must be set to ClusterIP.
  service_type: ClusterIP
  app_config:
    catalog:
      locations:
        - type: url
          target: https://GIT-CATALOG-URL/catalog-info.yaml
          
metadata_store:
  ns_for_export_app_cert: "default"
  app_service_type: ClusterIP

scanning:
  metadataStore:
    # Configuration is moved, so set this string to empty.
    url: ""

```

Where:

* `INGRESS-DOMAIN` is the subdomain for the host name that you point at the tanzu-shared-ingress service’s External IP address.
* `KP-DEFAULT-REPO` is a writable repository in your registry. Tanzu Build Service dependencies are written to this location. Examples:
  * Harbor has the form `kp_default_repository: "my-harbor.io/my-project/build-service"`.
  * Docker Hub has the form `kp_default_repository: "my-dockerhub-user/build-service"` or `kp_default_repository: "index.docker.io/my-user/build-service"`.
  * Google Cloud Registry has the form kp_default_repository: "gcr.io/my-project/build-service".
* `KP-DEFAULT-REPO-USERNAME` is the user name that can write to `KP-DEFAULT-REPO`. You can `docker push` to this location with this credential.
  * For Google Cloud Registry, use `kp_default_repository_username: _json_key`.
  * Alternatively, you can configure this credential as a secret reference.
* `KP-DEFAULT-REPO-PASSWORD` is the password for the user that can write to `KP-DEFAULT-REPO`. You can `docker push` to this location with this credential. You can also configure this credential by using a secret reference. See Install Tanzu Build Service for details.
  * For Google Cloud Registry, use the contents of the service account JSON file.
  * Alternatively, you can configure this credential as a secret reference.
* `SERVER-NAME` is the host name of the registry server. Examples:
  * Harbor has the form `server: "my-harbor.io"`.
  * Docker Hub has the form `server: "index.docker.io"`.
  * Google Cloud Registry has the form `server: "gcr.io"`.
* `REPO-NAME` is where workload images are stored in the registry. If this key is passed through the shared section earlier and AWS ECR registry is used, you must ensure that the `SERVER-NAME/REPO-NAME/buildservice` and `SERVER-NAME/REPO-NAME/workloads` exist. AWS ECR expects the paths to be pre-created. Images are written to `SERVER-NAME/REPO-NAME/workload-name`. Examples:
  * Harbor has the form repository: `"my-project/supply-chain"`.
  * Docker Hub has the form repository: `"my-dockerhub-user"`.
  * Google Cloud Registry has the form repository: `"my-project/supply-chain"`.
* `SSH-SECRET-KEY` is the SSH secret key in the developer namespace for the supply chain to fetch source code from and push configuration to. This field is only required if you use a private repository, otherwise, leave it empty.
* `GIT-CATALOG-URL` is the path to the `catalog-info.yaml` catalog definition file. You can download either a blank or populated catalog file from the Tanzu Application Platform product page. Otherwise, you can use a Backstage-compliant catalog you’ve already built and posted on the Git infrastructure.

Also see [Installing Tanzu Application Platform package and profiles > Full profile](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-install.html#full-profile-2).

### Install the package

```bash
tanzu package install tap -p tap.tanzu.vmware.com -v 1.3.2 --values-file tap-values.yaml -n tap-install
```

### Verify the package install

```
tanzu package installed list -A
```

### Update DNS with the Load Balancer Hostname 

Now that we have TAP deployed we can get the LB info and add it to our DNS record. Because AWS uses hostnames for LBs we will create a CNAME record in route53 for `*.tapdomain.companydomain.com` and point it at our LB.

to get the hostname of the LB use this:

```
kubectl get service -n tanzu-system-ingress envoy --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

validate it works. this should return a 404

```
curl -v http://test.tapdomain.companydomain.com
```

## Access

Obtain proxies

```bash
kubectl get httpproxy -A
```

Get training portals

```bash
kubectl get trainingportal -A
```
