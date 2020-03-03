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
    tempFile=$(mktemp /tmp/kube_fuzzy.XXXXXXXXXXXX)
    commandFile=$(mktemp /tmp/kube_fuzzy.command.XXXXXXXXXXXX)
    resultFile=$(mktemp /tmp/kube_fuzzy.result.XXXXXXXXXXXX)

    # Key bindings
    declare -A commands
    commands+=(
            ["edit"]="ctrl-e"
            ["delete"]="ctrl-t"
            ["describe"]="ctrl-b"
            ["logs"]="ctrl-l"
    )

    kubectl get $1 |
    sk --ansi --preview "{
        kubectl describe $1 {1} > $tempFile;
        lines=\$(echo \$(wc -l < $tempFile));
        eventsLine=\$(cat $tempFile | grep -n 'Events:' | cut -d: -f 1);
        echo \"-------------------------------------------------------------\"
        bat $tempFile --line-range \$eventsLine:\$lines; 
        echo \"-------------------------------------------------------------\"
        less -e $tempFile;
    }" --bind "${commands[delete]}:execute(kubectl delete $1 {}),${commands[edit]}:execute(echo 'edit' > $commandFile; echo {} > $resultFile)+abort,${commands[describe]}:execute(echo 'describe' > $commandFile; echo {} > $resultFile)+abort,${commands[logs]}:execute(echo 'logs' > $commandFile; echo {} > $resultFile)+abort"

    # Cleanup temporary files
    exitCode=$(echo $?)
    rm $tempFile
    unset tempFile
    run=$(cat $commandFile)
    result=$(cat $resultFile) # $(echo $(cat $resultFile | cut -d' ' -f1 | awk '$1=$1' ORS=' ' | cat)) # tr '\r\n' ' ')) # awk '$1=$1' ORS=' ' | cat)
    rm $commandFile
    rm $resultFile
    unset commandFile
    unset resultFile

    # Handle commands after skim exits
    if [[ $exitCode -eq 130 ]]; then # Skim was aborted
        if [[ ! -z "$run" ]]; then
            if [[ "$run" == "edit" ]]; then
                kubectl edit $1 "$result"
            elif [[ "$run" == "describe" ]]; then
                kubectl describe $1 "$result"
            fi
  
            if [[ $1 == "pods" ]]; then
                if [[ "$run" == "logs" ]]; then
                    kubectl logs "$result"
                fi
            else
                if [[ "$run" == "logs" ]]; then
                    echo "Can't get logs for type $1"
                fi
            fi
        else
            echo "Aborted"
        fi
    fi
}

alias kgp="kube_fuzzy pods"
alias kgd="kube_fuzzy deployments"