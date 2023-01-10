# Advanced Usage

This will cover the modifications needed to setup a more advanced supply chain with testing and scanning as well as a gitops integration for workloads. This assumes go have gone through the basic install and deployed a workload. We will re-use components that were previously documented. 

## Pre-reqs

* A developer namespace created per [this doc](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-set-up-namespaces.html). For this we assume `default` as the dev namespace.
* Have gone through the install with a basic supply chain and deployed a sample workload

## Setup Gitops

We will use github in this example, but any git repo should work. There are a number of different ways that the repo structure for gitops could be setup. in this case we will keep it very simple and just use one repo for everything. Official docs [here](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-scc-gitops-vs-regops.html#gitops-0)

1. Create a new git repo in your preferred git provider. name it `tapqs-gitops`
2. provide an authentication secret. replace `GIT-USERNAME` and `GIT-PASSWORD`. In github the password will be a PAT that you can generate in your developer settings.

```bash
cat <<'EOF'  | kubectl -n default apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: tapqs-git-secret
  annotations:
    tekton.dev/git-0: https://github.com
type: kubernetes.io/basic-auth
stringData:
  username: GIT-USERNAME
  password: GIT-PASSWORD
EOF
```

3. add the gitops secret to the service account in the dev namespace

```bash
kubectl patch sa default -n default --type "json" -p '[{"op":"add","path":"/secrets/-","value":{"name": "tapqs-git-secret"}}]'
```

4. create a branch for `workloads` and `deliverables` in the git repo.

5. create an app that syncs the deliverables and workloads into the cluster. replace `YOUR_ORG` with your github org.

```bash
cat <<'EOF'  | kubectl -n default apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-ns-sa
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-ns-role
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-ns-role-binding
subjects:
- kind: ServiceAccount
  name: default-ns-sa
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-ns-role

---
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: delivery-gitops
  namespace: default
spec:
  serviceAccountName: default-ns-sa
  fetch:
  - git:
      url: https://github.com/YOUR_ORG/tapqs-gitops
      ref: origin/deliverables
  template:
  - ytt: {}
  deploy:
  - kapp:
      rawOptions: ["--dangerous-allow-empty-list-of-resources=true"]
---
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: workloads-gitops
  namespace: default
spec:
  serviceAccountName: default-ns-sa
  fetch:
  - git:
      url: https://github.com/YOUR_ORG/tapqs-gitops
      ref: origin/workloads
  template:
  - ytt: {}
  deploy:
  - kapp:
      rawOptions: ["--dangerous-allow-empty-list-of-resources=true"]
EOF
```

## Setup a test pipeline
We will setup a basic testing pipeline that will always pass in this case. This is just an example, this can be modified to run real tests. Full docs can be found [here](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-scc-ootb-supply-chain-testing.html).

Run the following to create a pipeline in the developer namespace. For this we are using default as our dev namespace.
```bash
cat <<'EOF' | kubectl -n default apply -f -
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: developer-defined-tekton-pipeline
  labels:
    apps.tanzu.vmware.com/pipeline: test
spec:
  params:
    - name: source-url
    - name: source-revision
  tasks:
    - name: test
      params:
        - name: source-url
          value: $(params.source-url)
        - name: source-revision
          value: $(params.source-revision)
      taskSpec:
        params:
          - name: source-url
          - name: source-revision
        steps:
          - name: test
            image: gradle
            script: |-
              cd `mktemp -d`
              wget -qO- $(params.source-url) | tar xvz -m
              echo "all tests passed"
EOF
```



## Create a scan policy

We need to add a scan policy. This is a default policy.


```bash
kubectl apply -f - -o yaml << EOF
---
apiVersion: scanning.apps.tanzu.vmware.com/v1beta1
kind: ScanPolicy
metadata:
  name: scan-policy
  labels:
    'app.kubernetes.io/part-of': 'enable-in-gui'
spec:
  regoFile: |
    package main

    # Accepted Values: "Critical", "High", "Medium", "Low", "Negligible", "UnknownSeverity"
    notAllowedSeverities := ["Critical", "High", "UnknownSeverity"]
    ignoreCves := []

    contains(array, elem) = true {
      array[_] = elem
    } else = false { true }

    isSafe(match) {
      severities := { e | e := match.ratings.rating.severity } | { e | e := match.ratings.rating[_].severity }
      some i
      fails := contains(notAllowedSeverities, severities[i])
      not fails
    }

    isSafe(match) {
      ignore := contains(ignoreCves, match.id)
      ignore
    }

    deny[msg] {
      comps := { e | e := input.bom.components.component } | { e | e := input.bom.components.component[_] }
      some i
      comp := comps[i]
      vulns := { e | e := comp.vulnerabilities.vulnerability } | { e | e := comp.vulnerabilities.vulnerability[_] }
      some j
      vuln := vulns[j]
      ratings := { e | e := vuln.ratings.rating.severity } | { e | e := vuln.ratings.rating[_].severity }
      not isSafe(vuln)
      msg = sprintf("CVE %s %s %s", [comp.name, vuln.id, ratings])
    }
EOF
```

## Create a service account for accessing the metadata store

This is needed in order get scan results in the tap GUI. Official docs [here](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-scst-store-create-service-account.html#ro-serv-accts)

Create the service account and a secret:

```bash
kubectl apply -f - -o yaml << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metadata-store-ready-only
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: metadata-store-read-only
subjects:
- kind: ServiceAccount
  name: metadata-store-read-client
  namespace: metadata-store
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metadata-store-read-client
  namespace: metadata-store
  annotations:
    kapp.k14s.io/change-group: "metadata-store.apps.tanzu.vmware.com/service-account"
automountServiceAccountToken: false
---
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: metadata-store-read-client
  namespace: metadata-store
  annotations:
    kapp.k14s.io/change-rule: "upsert after upserting metadata-store.apps.tanzu.vmware.com/service-account"
    kubernetes.io/service-account.name: "metadata-store-read-client"
EOF
```


Get the token from the service account to be used in our TAP values file. Save this token somewhere for later use.

```bash
kubectl get secrets metadata-store-read-client -n metadata-store -o jsonpath="{.data.token}" | base64 -d
```


## Update TAP Values

We need to add a few things to our tap values file to make the new features work. the file below is an extension of the one from the basic install. Comments have been added to show what is new. All new sections will have a comment with `ADVANCED` in it.


Update your tap values yaml with the additional settings

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


profile: full
supply_chain: testing_scanning #ADVANCED - add testing and scanning

ootb_supply_chain_testing_scanning: #ADVANCED - add testing and scanning
  external_delivery: true #ADVANCED - makes the deliverable external for gitops
  registry:
    server: "SERVER-NAME"
    repository: "REPO-NAME"
  gitops:
     #ADVANCED - adding details to push config into git repo for gitops
    ssh_secret: "tapqs-git-secret"
    server_address: https://github.com/
    repository_owner: REPO-OWNER
    repository_name: tapqs-gitops

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
  service_type: ClusterIP
  app_config:
    #ADVANCED - add proxy for accessing metadata store from the UI for CVE results
     proxy:
      /metadata-store:
        target: https://metadata-store-app.metadata-store:8443/api/v1
        changeOrigin: true
        secure: false
        headers:
          Authorization: "Bearer TOKEN_HERE" #replace this token with the one from the command in the previous step
          X-Custom-Source: project-star
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

#ADVANCED - setup grype config for scanning
grype:
  namespace: "default"
  targetImagePullSecret: "registry-credentials"

```

Run this command to update the package

```bash
 tanzu package installed update  tap -p tap.tanzu.vmware.com -v 1.3.2 --values-file tap-values-advanced.yaml -n tap-install
```

## Deploy a workload with GitOps


### Setup the workload
We should already have a workload deployed. We will use this as the base for our gitops workload.

1. Get the workload yaml contents.

ex.
```bash
tanzu apps workload get <wokrload-name> --export
```

2. copy that yaml that is output and commit it to the `workloads` branch in our git repo under the filename `<workload-name>.yaml`

### Setup the Deliverable

Once the above is complete the workload should go through the full supply chain and create a deliverable for us. We need to put this deliverable in git.

1. Get the deliverable yaml from the cluster

```bash
kubectl get configmap <workload-name> -n default -o go-template='{{.data.deliverable}}'
```

2. Copy the yaml output from the above command and commit it to the `deliverables` branch in our git repo under the filename `<workload-name>.yaml`. Due to a current bug we need to add two labels to the yaml that was output.

```yaml
carto.run/workload-name: <workload-name>
carto.run/workload-namespace: default
```

At this point you should see a deliverable get deployed on the cluster and the app start to spin up. You can check using the below commands.

this should show knative revisions now.

```bash
tanzu apps workload get <workload-name>
```

this should show a deliverable for our workload

```bash
kubectl get deliverables
```

