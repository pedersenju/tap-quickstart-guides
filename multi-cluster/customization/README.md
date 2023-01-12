# Customizations to Tanzu Application Platform multi-cluster footprint configuration


## Add Learning Center overlay configuration

Copy [learningcenter-config-overlay.yaml](learningcenter-config-overlay.yaml) into the [multi-cluster](../) directory.

Add the following lines to the end of [tap-template-view.yaml](../tap-template-view.yaml)

```yaml
package_overlays:
- name:  learningcenter
  secrets:
  - name: learningcenter-config-overlay
```

Then follow the [update](../README.md#update) instructions to apply the changes.

The overlay will consume a TLS secret found in a specific namespace to appropriately configure Ingress.


## Consuming packages installed out-of-band

If you had installed packages (or K8s manifests or Helm charts) that TAP installs on your behalf (included in profile) prior to attempting installation of TAP, you will need to add exclusion rules to your template configuration.

For example, if you had installed [contour](https://projectcontour.io/) and [cert-manager](https://cert-manager.io/) prior to installing TAP, you would need to add the following lines to each `tap-template-{profile}.yaml` file:

```yaml
excluded_packages:
  - cert-manager.tanzu.vmware.com
  - contour.tanzu.vmware.com
```

Furthermore if you had installed a ClusterIssuer and Certificate, then you would need to uncomment and edit lines in your

* [config.yaml](../config.yaml) - see lines 22-26
* `tap-template-{profile}.yaml` - see line 11
