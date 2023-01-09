# Tanzu Application Platform Quickstart Usage Guide

## Prerequisites

As a developer you're going to want to have a few tools installed on your workstation.

At a minimum:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) CLI
  * Your kubeconfig context is set to the prepared cluster `kubectl config use-context {CONTEXT_NAME}`.  Replace `{CONTEXT_NAME}` with the context for the cluster you wish to target.
  * By the way, that cluster should have the Tanzu Application Platform installed on it.
* [tanzu](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-install-cli.html#download-and-unpack-the-tanzu-cli-and-kubectl-1) CLI
  * The `apps` plugin is installed. See the [Install Apps CLI plug-in](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-cli-plugins-apps-install-apps-cli.html).
* This Visual Studio Code [extension](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-vscode-extension-install.html)
* Ask your platform operator to create a new namespace on the target cluster for your workloads to run within.
  * Refer to these [instructions](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-set-up-namespaces.html).

## Accelerators, increasing development velocity

What are accelerators?  An [accelerator](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-getting-started-deploy-first-app.html) is essentially comprised of a _template_ (e.g., initial source code and configuration) for creating a cloud-native application compliant with an enterprise's governance standards and a _workload_ custom resource definition for interfacing with Tanzu Application Platform.  This allows developers to ignore Dockerfiles or other Kubernetes resources that have dependencies on the target application infrastructure.

Let's see what accelerators are available:

```
tanzu accelerator list
```

Sample output

```
$ tanzu accelerator list

NAME                       READY   REPOSITORY

```

// FIXME Update sample output above

What if we want to create a new application based on one of the above?

```
tanzu accelerator generate {application-name} --server-url https://accelerator.{domain} --options '{"projectName":"{application-name}", "includeKubernetes": true}'
```

Sample output

```
$ cd /tmp
$ tanzu accelerator generate tanzu-java-web-app --server-url https://accelerator.lab.zoolabs.me --options '{"projectName":"my-java-web-app", "includeKubernetes": true}'
zip file my-java-web-app.zip created
```
> This will download a zip file containing the source code and configuration for the new project named `my-java-web-app` into the directory where the command was executed.

Let's unpack what we downloaded and explore

```
unzip -o unzip -o my-java-web-app.zip
cd my-java-web-appstatyus
ls -la
```
> Note that this is a Java application built with [Maven](https://maven.apache.org/).  In the top-level folder you'll see a `config` directory plus a couple files: `catalog-info.yaml` and `Tiltfile`.  The config directory contains the [Workload](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-cli-plugins-apps-command-reference.html) custom resource definition.  The `Tiltfile` is used by the [Tanzu Developer Tools Visual Studio Code extension](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-vscode-extension-getting-started.html) to help you with inner-loop development (e.g., build, run, test on your local workstation).  The `catalog-info.yaml` file is consumed by [Tanzu Application Platform GUI](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.3/tap/GUID-tap-gui-catalog-catalog-operations.html#update-software-catalogs-4)'s Organization Catalog.

## Prepare new project repository

Ultimately what you'd want is for this (or any) project to be managed in a distributed source control repository, because you're on a product team, and you'll all collaborate to add new features or fix defects over time.  So let's prepare a repository and get this project's source pushed.  (In this example we'll use Github, but you could target any git-compatible repository provider).

```
git init
gh repo create
git branch -m master main
git add .
git status
git commit -m "Initial commit"
git push -u origin main
```
> Assumes you have both the [git](https://git-scm.com/downloads) and [gh](https://github.com/cli/cli#installation) CLI installed, and that you have [authenticated](https://cli.github.com/manual/gh_auth_login) to Github.

Sample interaction

```
❯ git init
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint:
hint:   git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint:   git branch -m <name>
Initialized empty Git repository in /tmp/my-java-web-app/.git/
❯ gh repo create
? Repository name my-java-web-app
? Repository description Sample Java Web App based on a Tanzu Application Platform Accelerator
? Visibility Public
? This will add an "origin" git remote to your local repository. Continue? Yes
✓ Created repository pacphi/my-java-web-app on GitHub
✓ Added remote https://github.com/pacphi/my-java-web-app.git
❯ git branch -m master main
❯ git add .
❯ git status
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
        new file:   .gitignore
        new file:   .mvn/wrapper/MavenWrapperDownloader.java
        new file:   .mvn/wrapper/maven-wrapper.jar
        new file:   .mvn/wrapper/maven-wrapper.properties
        new file:   .tanzu/tanzu_tilt_extensions.py
        new file:   .tanzu/wait.sh
        new file:   LICENSE
        new file:   README.md
        new file:   Tiltfile
        new file:   accelerator-log.md
        new file:   catalog-info.yaml
        new file:   config/workload.yaml
        new file:   mvnw
        new file:   mvnw.cmd
        new file:   pom.xml
        new file:   src/main/java/com/example/springboot/Application.java
        new file:   src/main/java/com/example/springboot/HelloController.java
        new file:   src/main/resources/application.yml
        new file:   src/test/java/com/example/springboot/HelloControllerTest.java
❯ git commit -m "Initial commit"
[main (root-commit) 4c2c32d] Initial commit
 19 files changed, 1272 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 .mvn/wrapper/MavenWrapperDownloader.java
 create mode 100644 .mvn/wrapper/maven-wrapper.jar
 create mode 100644 .mvn/wrapper/maven-wrapper.properties
 create mode 100644 .tanzu/tanzu_tilt_extensions.py
 create mode 100755 .tanzu/wait.sh
 create mode 100644 LICENSE
 create mode 100644 README.md
 create mode 100644 Tiltfile
 create mode 100644 accelerator-log.md
 create mode 100644 catalog-info.yaml
 create mode 100644 config/workload.yaml
 create mode 100755 mvnw
 create mode 100644 mvnw.cmd
 create mode 100644 pom.xml
 create mode 100644 src/main/java/com/example/springboot/Application.java
 create mode 100644 src/main/java/com/example/springboot/HelloController.java
 create mode 100644 src/main/resources/application.yml
 create mode 100644 src/test/java/com/example/springboot/HelloControllerTest.java
 ❯ git push -u origin main
Enumerating objects: 37, done.
Counting objects: 100% (37/37), done.
Delta compression using up to 12 threads
Compressing objects: 100% (27/27), done.
Writing objects: 100% (37/37), 60.97 KiB | 8.71 MiB/s, done.
Total 37 (delta 0), reused 0 (delta 0), pack-reused 0
To https://github.com/pacphi/my-java-web-app.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

## Update workload CRD

Inspect the content of `workload.yaml`:

```
cat config/workload.yaml
```
> Note the value of `spec.source.git.url`. You're going to update this value to be the git repository you just pushed.

Update the repo value:

```
cd config
sed -i 's/sample-accelerators/pacphi/g' workload.yaml
cd ..
```
> Note [sed](https://www.gnu.org/software/sed/manual/sed.html) is used to replace the owner of the `github.com` repository above; don't blindly follow, make sure you edit the value of `spec.source.git.url` so that it references your own git repository.

Commit and push this change:

```
git add .
git status
git commit -m "Update workload.yaml source repository"
git push -u origin main
```

## Build, package, and deploy workload to a target cluster

How do we build, package and deploy this application? I'm glad you asked.

```
tanzu apps workload create my-java-web-app --git-repo https://github.com/pacphi/my-java-web-app --git-branch main --type web
```
> Replace the values for the parameters `--git-repo` and `--git-branch` above with your own.

Sample interaction

```
$ tanzu apps workload create my-java-web-app --git-repo https://github.com/pacphi/my-java-web-app --git-branch main --type web

Create workload:
      1 + |apiVersion: carto.run/v1alpha1
      2 + |kind: Workload
      3 + |metadata:
      4 + |  labels:
      5 + |    apps.tanzu.vmware.com/workload-type: web
      6 + |  name: my-java-web-app
      7 + |  namespace: default
      8 + |spec:
      9 + |  source:
     10 + |    git:
     11 + |      ref:
     12 + |        branch: main
     13 + |      url: https://github.com/pacphi/my-java-web-app

? Do you want to create this workload? Yes
```

To watch the progress of your request:

```
tanzu apps workload tail my-java-web-app --since 10m --timestamp
```
> Type `Ctrl+c` to exit.

Congratulations! Your first workload has been built, packaged as a container image, published to Harbor, then deployed to a target cluster.

> This should get you asking the question: "Could I migrate an existing application?"


## Troubleshooting stalled workload deployments

The first place you may want to look is the `pod` where the build is happening. If you were attempting to deploy `my-java-web-app`, then you could execute:

```
kubectl describe po -l image.kpack.io/image=my-java-web-app
```

// FIXME add an example of what you might see and how to triage

## List workloads

```
tanzu apps workload list
```


## Get details for a workload

```
tanzu app workload get {app-name}
```

Sample interaction

```
$ tanzu apps workload get my-java-web-app

```

// FIXME Add an example of the output above

> Go visit that URL in your favorite browser.  Notice that the first request takes a little more time to return a response.  This is is because the app instance, when not receiving requests, will scale to zero.  This is an in-built benefit of [KNative serving](https://knative.dev/docs/serving/autoscaling/scale-to-zero/) and [Cloud Native Runtimes](https://docs.vmware.com/en/Cloud-Native-Runtimes-for-VMware-Tanzu/1.0/tanzu-cloud-native-runtimes-1-0/GUID-cnr-overview.html).


## Update workload

```
tanzu app workload update --help
```
> Gets you help for all the options available to you for updating your workload.

## Delete workload(s)

```
tanzu apps workload delete --all -n {namespace}
```
> Delete all workloads within the `{namespace}`.  Replace `{namespace}` with an actual namespace name.

Sample interaction

```
$ tanzu apps workload delete --all -n default
? Really delete all workloads in the namespace "default"? Yes

Deleted workloads in namespace "default"
```

```
tanzu apps workload delete -f {path-to-workload-yaml-file}
```
> Deletes a single workload.  Replace `{path-to-workload-yaml-file}` with an actual path to a `workload.yaml` file.


## Getting your app to appear in the Tanzu Application Platform GUI Catalog

Visit the Git repository containing the contents of the _blank catalog_ you [created earlier]() using your favorite browser.

You'll want to edit and add an entry to `catalog-info.yaml` for each application deployed with `tanzu apps workload create`.

Have a look at this sample repository's [catalog-info.yaml](https://github.com/pacphi/tap-gui-catalog/blob/main/catalog-info.yaml) file for an example of what an entry looks like.

> The default catalog refresh is 200 seconds.  After your catalog refreshes you can see the entry in the catalog and interact with it.


## Other examples

### Source


* [x] [Dotnet Core](https://github.com/pacphi/AltPackageRepository) with alternative Nuget package usage
  * Deploy with

    ```
    tanzu apps workload create dotnet-core-sample --git-repo https://github.com/pacphi/AltPackageRepository --git-branch main --type web --label app.kubernetes.io/part-of=dotnet-core-sample
    ```

* [x] [Go](https://github.com/pacphi/go-gin-web-server)
  * Deploy with

    ```
    tanzu apps workload create go-sample --git-repo https://github.com/pacphi/go-gin-web-server --git-branch master --type web --label app.kubernetes.io/part-of=go-sample
    ```

* [x] [Python](https://github.com/SaiJeevanPuchakayala/CryptoCurrency-Screener)
  * Deploy with

    ```
    tanzu apps workload create crypto-screener --git-repo https://github.com/SaiJeevanPuchakayala/CryptoCurrency-Screener --git-branch main --type web --label app.kubernetes.io/part-of=crypto-screener
    ```

* [x] [PHP](https://github.com/pacphi/tetris)
  * Deploy with

    ```
    tanzu apps workload create tetris --git-repo https://github.com/pacphi/tetris --git-branch main --type web --label app.kubernetes.io/part-of=tetris
    ```
