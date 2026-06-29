# Exercise 14: Ambient Mesh

## Difficulty
Intermediate

## Estimated effort
90-180 minutes

## Learning objectives
- Understand module architecture and failure modes

## Architectural context
This module builds on previous exercises and contributes to production-style Istio operations.

## Prerequisites
- Previous exercises completed
- Access to lab cluster

## Files used
- See module-specific manifests and scripts in repository paths

## Environment checks
- kubectl connectivity
- namespace/workload readiness

## Implementation steps
1. Follow scripted sequence
2. Apply manifests
3. Validate expected behavior

## Commands
Refer to script and manifest paths in this module and .

## Expected output
Command outputs should show successful resource creation and healthy pod status.

## Verification
Perform explicit kubectl controls the Kubernetes cluster manager.

 Find more information at: https://kubernetes.io/docs/reference/kubectl/

Basic Commands (Beginner):
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects

Basic Commands (Intermediate):
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and label selector

Deploy Commands:
  rollout         Manage the rollout of a resource
  scale           Set a new size for a deployment, replica set, or replication controller
  autoscale       Auto-scale a deployment, replica set, stateful set, or replication controller

Cluster Management Commands:
  certificate     Modify certificate resources
  cluster-info    Display cluster information
  top             Display resource (CPU/memory) usage
  cordon          Mark node as unschedulable
  uncordon        Mark node as schedulable
  drain           Drain node in preparation for maintenance
  taint           Update the taints on one or more nodes

Troubleshooting and Debugging Commands:
  describe        Show details of a specific resource or group of resources
  logs            Print the logs for a container in a pod
  attach          Attach to a running container
  exec            Execute a command in a container
  port-forward    Forward one or more local ports to a pod
  proxy           Run a proxy to the Kubernetes API server
  cp              Copy files and directories to and from containers
  auth            Inspect authorization
  debug           Create debugging sessions for troubleshooting workloads and nodes
  events          List events

Advanced Commands:
  diff            Diff the live version against a would-be applied version
  apply           Apply a configuration to a resource by file name or stdin
  patch           Update fields of a resource
  replace         Replace a resource by file name or stdin
  wait            Wait for a specific condition on one or many resources
  kustomize       Build a kustomization target from a directory or URL

Settings Commands:
  label           Update the labels on a resource
  annotate        Update the annotations on a resource
  completion      Output shell completion code for the specified shell (bash, zsh, fish, or powershell)

Subcommands provided by plugins:

Other Commands:
  api-resources   Print the supported API resources on the server
  api-versions    Print the supported API versions on the server, in the form of "group/version"
  config          Modify kubeconfig files
  kuberc          Manage kuberc configuration files
  plugin          Provides utilities for interacting with plugins
  version         Print the client and server version information

Usage:
  kubectl [flags] [options]

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands). and  checks tied to the module goals.

## Failure experiments
Introduce one controlled fault and observe control/data-plane behavior.

## Troubleshooting
Use diagnostics collectors in  and .

## Cleanup
Remove module-specific resources and restore baseline.

## Architectural lessons
Capture trade-offs observed between reliability, security, and operational complexity.

## Production considerations
Translate lab choices to production-safe patterns.

## Self-assessment questions
1. What failure mode was observed?
2. How was it diagnosed?
3. What policy/configuration fixed it?

## Milestone status
Detailed implementation for advanced modules is tracked as TODO for subsequent milestones.
