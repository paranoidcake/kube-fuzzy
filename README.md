# kube-fuzzy
Simplify working with kubectl on the command line with skim.

## Contents

 - [Usage](#usage)
   - [Aliases](#aliases)
   - [Keybinds](#keybinds)
 - [Requirements](#requirements)
 - [Installation](#installation)
   - [Dependencies](#dependencies)
     - [MacOS](#macos)
     - [Fedora](#fedora)
     - [Arch Linux](#arch-linux)
   - [Source the script](#source-the-script)
 - [Configuring](#configuring)
   - [Aliases](#aliases-1)
   - [Keybinds](#keybinds-1)
   - [Actions](#actions)

## Usage

kube-fuzzy aims to replace kubectl with an interactive prompt by using skim.

`kube-fuzzy.sh` includes 2 functions to source in your shell:
  - `kube_fuzzy`, to provide the main functionality
  - and `kube_define`, a helper function for extending that functionality.

### Aliases

`kube-fuzzy`'s default aliases are designed to mimic common aliases used for kubectl. The goal is to change the flow of running these commands, for eg. `kgpo | grep name; kdpo full-pod-name | less; krmpo full-pod-name` into a single easier to control, `kgp`.

The default aliases are:

 - `kgp`, to replace `kubectl get pods`, `edit pods`, so on
 - `kgd`, to replace `kubectl get deployments`, `edit deployments`, so on
 - `kgs`, to replace `kubectl get services`
 - and `kgsec`, to replace `kubectl get secrets`
 
You can also call the `kube_fuzzy` function directly, like so:

    kube_fuzzy pods

or with `bat` installed:

    kube_fuzzy pods --events

which will place the `Events:` part of the preview on the top to read updates more easily.
`kgp`, `kgd` and `kgs` by default use this flag.

 - Note this may cause a "double output" effect if the resource reports no events when described (eg. `secrets`), so only use with relevant resources.

### Keybinds

The default keybinds are:

- `ctrl-e`: **E**dit selected resources after exit
- `ctrl-t`: Dele**t**e currently highlighted resource
- `ctrl-b`: Descri**b**e selected resources after exit
- `ctrl-l`: **L**og selected pod after exit
- `ctrl-k`: Get containers of selected pod, and display its logs in sk
- `ctrl-o`: Base64 dec**o**de the data fields of selected secret after exit
- `ctrl-n`: No action, defaults to outputting selected objects

If you would prefer other keybinds or these interfere with your terminal, see [Configuring#Keybinds](#keybinds-1).

Keybinds will queue an action to be performed after accepting a selection.
You can see the last queued action at the top of the preview pane on the right side of the screen.
To add more actions, see [Configuring#Actions](#actions)

- Note: This will only update with the preview window itself, which is limited by how fast `kubectl` can run.

## Requirements
  - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
  - [sk](https://github.com/lotabout/skim)
  - bash >= v4, zsh or similar. Fish cannot run the script
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

 - Kubectl (if required)
 
       pacman -S kubectl
    
 - Skim

       pacman -S skim

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
    
      - Note you will have to change the path in your `.bashrc` file if you move the kube-fuzzy.sh file
    
4. Open a new shell or source your `.bashrc` file

5. You're done!

## Configuring

### Aliases

By default kube-fuzzy.sh has 4 aliases which use the `kube_fuzzy` command, and its optional --events flag:

- `kgp="kube_fuzzy pods --events"`, for pods
- `kgd="kube_fuzzy deployments --events"`, for deployments
- `kgs="kube_fuzzy services --events"`, for services
- `kgsec="kube_fuzzy secrets"`, for secrets

These aliases are defined at the end of the `kube-fuzzy.sh` file, where you can change, remove, or add to them.

You can also call the `kube_fuzzy` command from your `.bashrc` file after sourcing, if you prefer to have your aliases there.

### Keybinds

By default keybinds are defined in files in the `keybinds/` folder, with the format `action=binding`, seperated by new lines. 

`action` **must** match what comes after `kube_` in it's function name in `actions.sh`.
  - For example, the action name for `kube_describe()` is `describe`.

They can be defined:

 - Through `kube_define`, which accepts a resource (eg. `pods` or `any`), and then a string of space seperated keybinds.
    - Eg. `kube_define pods 'logs=ctrl-l containers=ctrl-k'`, which will:
      - Create a file 'pods' in `keybinds/`, which will be loaded whenever `kube_fuzzy` is called on `pods`
      - Define the keybind `ctrl-l` to call `kube_logs()` from `actions.sh`
      - Define the keybind `ctrl-k` to call `kube_containers()` from `actions.sh`
  
 - Or manually by creating / editing a file in `keybinds/`, following the above format. You can view some examples in the `any`, `pods` and `secrets` files that come with the repo.

#### Loading keybinds

Keybinds are loaded automatically based on the resource name. `kube_fuzzy` will check if there is a file matching the resource name (eg. `pods`) and read from it.

The `any` file's keybinds are also applied on any resource type.

This allows for global and resource-specific keybinds to be defined.

#### Accepted keys

For a list of accepted keys see:

<details><summary>Available keys from the sk man page</summary>
 
```
AVAILABLE KEYS: (SYNONYMS)
           ctrl-[a-z]
           ctrl-space
           ctrl-alt-[a-z]
           alt-[a-zA-Z]
           alt-[0-9]
           f[1-12]
           enter       (ctrl-m)
           space
           bspace      (bs)
           alt-up
           alt-down
           alt-left
           alt-right
           alt-enter   (alt-ctrl-m)
           alt-space
           alt-bspace  (alt-bs)
           alt-/
           tab
           btab        (shift-tab)
           esc
           del
           up
           down
           left
           right
           home
           end
           pgup        (page-up)
           pgdn        (page-down)
           shift-up
           shift-down
           shift-left
           shift-right
           alt-shift-up
           alt-shift-down
           alt-shift-left
           alt-shift-right
           or any single character
```

</details>

### Actions

Actions are defined in the `actions.sh` file in the same directory as `kube-fuzzy.sh`.

To implement a new action, define it as a function in `actions.sh` with the prefix `kube_`. It must accept a kubernetes resource for argument 1, and a space seperated list of names of those resources for argument 2.

To get your action called from within `kube-fuzzy.sh`, give it a keybind, as described in [Configuring#Keybinds](#keybinds-1)

Some exit codes are available, which `kube-fuzzy.sh` will print an error message for. To utilise them simply return their value.

Currently they are:
| Exit Code | Error |
|---|---|
| 3 | Incompatible resource |
| 4 | Incompatible with multiple resources selected |

`kube-fuzzy.sh` will propagate any code recieved from a function called in `actions.sh` to the shell it was executed in

#### Example implementation: Describe

1. Define the function in `actions.sh`

```bash
function kube_describe() {
    resource="$1"
    result="$2"
    kubectl describe "$resource" "$result"
}
```

2. Give it a keybind by calling `kube_define` from your shell:

       kube_define any 'describe=ctrl-b'
    
    (This can be done in other ways, see [Configuring#Keybinds](#keybinds-1) for details)

3. It will now be runnable with `ctrl-b` when running `kube_fuzzy`
