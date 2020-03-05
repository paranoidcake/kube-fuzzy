# kube-fuzzy
Simplify working with kubectl on the command line with skim.

## Usage

### Aliases

The default aliases are:

 - `kgp`, to replace `kubectl get pods`
 - `kgd`, to replace `kubectl get deployments`
 - `kgs`, to replace `kubectl get services`
 - and `kgsec`, to replace `kubectl get secrets`
 
You can also call the `kube_fuzzy` function directly, like so:

    kube_fuzzy pods

or with `bat` installed:

    kube_fuzzy pods --events
    
which will place the `Events:` part of the preview on the top to read updates quickly.
`kgp`, `kgd` and `kgs` by default use this flag (see [Configuring](#Configuring)).

 - Note this will cause a "double output" effect if the resource reports no events when described (eg. `secrets`), so only use with relevant resources.

### Keybinds

The default keybinds are:

- `ctrl-e`: **E**dit selected resources after exit
- `ctrl-t`: Dele**t**e currently highlighted resource*
- `ctrl-b`: Descri**b**e selected resources after exit
- `ctrl-l`: **L**og selected pod after exit
- `ctrl-k`: Get containers of selected pod, and display its logs in sk
- `ctrl-o`: Base64 decode the data fields of selected secret after exit
- `ctrl-n`: No action, defaults to outputting selected objects

These keybinds can be found and modified from `kube-fuzzy.sh`. See [Configuring](#Configuring).

Many keybinds will queue an action to be performed after accepting a selection.
You can see the last queued action at the top of the preview pane on the right side of the screen.

- Note: This will only update with the preview window itself, which is limited by how fast `kubectl` can run.

## Requirements
  - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
  - [sk](https://github.com/lotabout/skim)
  - bash >= v4, zsh or similar
  - Optional:
    - [bat](https://github.com/sharkdp/bat), used for the --events formatting flag

## Installation

### Dependencies

#### MacOS

- Kubectl (if required)

      brew install kubectl

- Skim

      brew install sk

- Optionally, to use the `--events` flag

      brew install bat

#### Fedora

 - Kubectl (if required): see their [install guide](https://kubernetes.io/docs/tasks/tools/install-kubectl)

 - Skim
 
        dnf install skim
      
 - Optionally, to use the `--events` flag
 
        dnf install bat

#### Arch Linux

    pacman -S skim kubectl

- Optionally, to use the `--events` flag

      pacman -S bat

### Source the script

1. Clone the repo where you want your installation to be

       git clone https://github.com/paranoidcake/kube-fuzzy

2. `cd` to the newly created directory

       cd kube-fuzzy

3. Depending on your shell, run:

    - Bash

          echo "source $(pwd)/kube-fuzzy.sh" >> ~/.bashrc

    - Zsh

          echo "source $(pwd)/kube-fuzzy.sh" >> ~/.zshrc

    - Or source it manually
    
4. Open a new shell or source your `.bashrc` file

5. You're done!

## Configuring

By default kube-fuzzy.sh has 4 aliases which use the `kube_fuzzy` command, and its optional --events flag:

- kgp=`kube_fuzzy pods --events`, for listing pods
- kgd=`kube_fuzzy deployments --events`, for listing deployments
- kgs=`kube_fuzzy services --events`, for listing services
- kgsec=`kube_fuzzy secrets`, for listing secrets

These aliases are defined at the end of the `kube-fuzzy.sh` file, where you can change, remove, or add to them.

You can also call the `kube_fuzzy` command from your rc file after sourcing, if you prefer to have your aliases there.

`kube_fuzzy` takes a Kubernetes resource as an argument, and will have different actions available based on what resource is passed.
