# kube-fuzzy
Simplify working with kubectl on the command line with skim.

## Usage

kube-fuzzy aims to replace this:

<img width="600" alt="Screenshot 2020-03-06 at 11 48 59" src="https://user-images.githubusercontent.com/33574023/76081193-7d4fa880-5fa0-11ea-8333-cbb1fb7b4bcf.png">

with an interactive prompt like this:

<img width="600" alt="Screenshot 2020-03-06 at 11 49 47" src="https://user-images.githubusercontent.com/33574023/76081247-9e17fe00-5fa0-11ea-81d3-0b0dab104677.png">

by using skim. You can watch the [fuzzy search](https://drive.google.com/file/d/1I78paX1V3ZKyVqJo--OIf5eUMhylabVx/view) and [other features](https://drive.google.com/open?id=1zBXT-qXflnML-4SSndWklCn-h1sIODbM) in action too.

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

which will place the `Events:` part of the preview on the top to read updates quickly.
`kgp`, `kgd` and `kgs` by default use this flag (see [Configuring](#Configuring)).

 - Note this may cause a "double output" effect if the resource reports no events when described (eg. `secrets`), so only use with relevant resources.

### Keybinds

The default keybinds are:

- `ctrl-e`: **E**dit selected resources after exit
- `ctrl-t`: Dele**t**e currently highlighted resource*
- `ctrl-b`: Descri**b**e selected resources after exit
- `ctrl-l`: **L**og selected pod after exit
- `ctrl-k`: Get containers of selected pod, and display its logs in sk
- `ctrl-o`: Base64 dec**o**de the data fields of selected secret after exit
- `ctrl-n`: No action, defaults to outputting selected objects

If you would prefer other keybinds or these interfere with your terminal, see [Configuring#Keybinds](#Configuring/Keybinds).

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

By default keybinds are defined in the commands array (on line 21), with the format `["action"]="binding"` as:

```bash
# Key bindings
declare -A commands
commands+=(
    ["none"]="ctrl-n"
    ["delete"]="ctrl-t"
    ["edit"]="ctrl-e"
    ["describe"]="ctrl-b"
    ["logs"]="ctrl-l"
    ["containers"]="ctrl-k"
    ["decode"]="ctrl-o"
)
```

From the `sk` man page:

<details><summary>Available keys</summary>
 
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
