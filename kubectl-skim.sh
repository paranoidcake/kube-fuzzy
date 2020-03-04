#
# Function and aliases to utilise skim and bat to edit kubernetes pods and deployments
#
# Requirements:
#       sk  (https://github.com/lotabout/skim)
#       bat (https://github.com/sharkdp/bat)
#       bash >= v4, zsh, or any other shell with associative array support
#
# Usage:
#       Source the file in your shell, or add to your rc file
#

function kube_fuzzy () {
    # Temporary files for reading / writing data from skim
    local tempFile=$(mktemp /tmp/kube_fuzzy.XXXXXXXXXXXX)
    local commandFile=$(mktemp /tmp/kube_fuzzy.command.XXXXXXXXXXXX)
    local descriptionFile=$(mktemp /tmp/kube_fuzzy.description.XXXXXXXXXXXX)
    echo "none" > $commandFile

    # Key bindings
    declare -A commands
    commands+=(
            ["edit"]="ctrl-e"
            ["delete"]="ctrl-t"
            ["describe"]="ctrl-b"
            ["logs"]="ctrl-l"
            ["none"]="ctrl-n"
    )

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
        }" --bind "${commands[delete]}:execute(kubectl delete $1 {}),${commands[edit]}:execute(echo 'edit' > $commandFile),${commands[describe]}:execute(echo 'describe' > $commandFile),${commands[logs]}:execute(echo 'logs' > $commandFile),${commands[none]}:execute(echo 'none' > $commandFile)")

    # Cleanup temporary files
    local exitCode=$(echo $?)
    rm $tempFile
    rm $descriptionFile
    local run=$(cat $commandFile)
    rm $commandFile
    
    if [[ "$run" != "none" ]]; then
        local result=$(echo $result | awk '{ print $1 }' | tr '\n' ' ')
        if [[ "$run" == "edit" ]]; then
            kubectl edit $1 $result
        elif [[ "$run" == "describe" ]]; then
            kubectl describe $1 $result
        fi
  
        if [[ $1 == "pods" ]]; then
            if [[ "$run" == "logs" ]]; then
                kubectl logs $result
            fi
        else
            if [[ "$run" == "logs" ]]; then
                echo "Can't get logs for type $1"
            fi
        fi
    else
        echo $result
    fi
}


alias kgp="kube_fuzzy pods"
alias kgd="kube_fuzzy deployments"
