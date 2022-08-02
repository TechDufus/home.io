# FLUX Nodes

This role will prep a node for the RunOnFlux OS to be installed.

This role ensures that docker is installed for a specific user, and copy out some config files. FOr the sake of simplicity, I still manually must install FluxOS manually after this role is applied.'

Manually running / installing FluxOS myself allows me to see the progress of the script, and a rough ETA as to when it will be finished. All of this is suppressed by ansible if ran in this role.

## Manual Steps POST-Role application.

1. `echo "2" | multitoolbox`
   1. This will run the install script.
2. `echo "14" | multitoolbox`
   1. This will enable and configure uPnP for the node.
3. `echo "4" | multitoolbox`
   1. This will configure watchdog to auto-update FluxOS, FluxDaemon, and FluxBench for the node.

