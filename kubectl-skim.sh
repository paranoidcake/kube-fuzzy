#
# Function and aliases to utilise skim and bat to edit kubernetes pods and deployments
#
# Requirements:
#       sk  (https://github.com/lotabout/skim)
#       bat (https://github.com/sharkdp/bat)
#       bash >= v4, zsh, or any other shell with associative array support
#       kubectl
#
# Usage:
#       Source the file in your shell, or add to your rc file
#       See the commands array for keybindings, which by default are:
#           - ctrl-e: Edit selected objects after exit
#           - ctrl-t: Delete currently highlighted object*
#           - ctrl-b: Describe selected objects after exit
#           - ctrl-l: Log selected pods after exit
#           - ctrl-k: Get containers of selected pod, and display their logs in sk
#           - ctrl-n: No action, defaults to outputting selected objects
#       These keybinds and their behaviour can be changed, see #Configuring#Defining keybinds
#
# Configuring:
#       Defining keybinds:
#           - Keybinds are defined in the commands array, in the form ['action']='key(s)'
#           - Actions are defined in the actions variable, which cannot have leading whitespace and are seperated by newlines
#       Selection + actions:
#           - The default behaviour of most actions is to write that action's name to be executed*, using execute(echo 'action' > $commandFile)
#           - Accepting the selection of a kubernetes object (or multiple with Tab) will execute the last written action
#       Executing actions:
#           - Escaping / cancelling is handled when executing actions
#           - Some actions can be type specific (eg. logs) by comparing against the $1 parameter. This should be handled when executing the action
#       Preview window:
#           - The preview window will execute `$SHELL -c` on the string passed to the --preview flag each time a line is highlighted
#
#       *By default the 'delete' action does not act on the current selection, or wait for the selection to be accepted to execute.
#           The currently highlighted line is subsituted instead, see `man sk` and the execute() paired with 'delete' in actions for details
#

function kube_fuzzy () {
    # Temporary files for reading / writing data from skim
    local tempFile=$(mktemp /tmp/kube_fuzzy.XXXXXXXXXXXX)
    local commandFile=$(mktemp /tmp/kube_fuzzy.command.XXXXXXXXXXXX)
    echo "none" > $commandFile

    # Key bindings
    declare -A commands
    commands+=(
            ["edit"]="ctrl-e"
            ["delete"]="ctrl-t"
            ["describe"]="ctrl-b"
            ["logs"]="ctrl-l"
            ["containers"]="ctrl-k"
            ["none"]="ctrl-n"
    )

    actions=$(
echo -e "${commands[none]}:execute(echo 'none' > $commandFile)
${commands[delete]}:execute(kubectl delete $1 {1})
${commands[edit]}:execute(echo 'edit' > $commandFile)
${commands[describe]}:execute(echo 'describe' > $commandFile)
${commands[logs]}:execute(echo 'logs' > $commandFile)
${commands[containers]}:execute(echo 'containers' > $commandFile)" | tr '\n' ',')

    local result=$(kubectl get $1 |
    sk -m --ansi --preview "{
        echo \"Last command was: \$(cat $commandFile) (updates with preview window)\";
        echo '';
        kubectl describe $1 {1} > $tempFile;
        lines=\$(echo \$(wc -l < $tempFile));
        eventsLine=\$(cat $tempFile | grep -n 'Events:' | cut -d: -f 1);
        echo \"-------------------------------------------------------------\"
        bat $tempFile --line-range \$eventsLine:\$lines; 
        echo \"-------------------------------------------------------------\"
        less -e $tempFile;
        }" --bind "$actions")

    # Cleanup temporary files, and store their contents for use
    local exitCode=$(echo $?)
    rm $tempFile
    local run=$(cat $commandFile)
    rm $commandFile

    if [[ -z $result ]]; then           # No selection made
        echo "Aborted"
    elif [[ "$run" != "none" ]]; then   # Execute action
        local result=$(echo $(echo $result | awk '{ print $1 }' | tr '\n' ' '))
        if [[ "$run" == "edit" ]]; then
            kubectl edit $1 $result
        elif [[ "$run" == "describe" ]]; then
            kubectl describe $1 $result
        fi
  
        if [[ $1 == "pods" ]]; then     # Run pod specific actions
            if [[ "$run" == "logs" ]]; then
                kubectl logs $result
            elif [[ "$run" == "containers" ]]; then
                if [[ $result == *" "* ]]; then
                    echo "WIP: Can't currently handle multiple pods' containers"
                else
                    echo "Fetching containers..."
                    contNames=$(printf '%s\n' $(kubectl get pods $result -o jsonpath='{.spec.containers[*].name}'))
                    initContNames=$(printf '%s\n' $(kubectl get pods $result -o jsonpath='{.spec.initContainers[*].name}'))
                    logCont=$(echo -e "$contNames\n$initContNames" | sk --ansi --preview "kubectl logs $result -c {}")
                    if [[ ! -z $logCont ]]; then
                        kubectl logs $result -c $logCont
                    fi

                fi
            fi
        else
            if [[ "$run" == "logs" ]]; then
                echo "Can't get logs for type $1"
            elif [[ "$run" == "containers" ]]; then
                echo "Can't get containers for type $1"
            fi
        fi
    else
        echo -e "$result"
    fi
}


alias kgp="kube_fuzzy pods"
alias kgd="kube_fuzzy deployments"
