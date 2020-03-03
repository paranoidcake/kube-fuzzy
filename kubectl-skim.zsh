#
# Functions to utilise skim and bat to edit kubernetes pods and deployments
#
# Requirements:
#       sk  (https://github.com/lotabout/skim)
#       bat (https://github.com/sharkdp/bat)
#

function kubeFuzzy () {
        # Temporary files for reading / writing data from skim
        tempFile=$(mktemp /tmp/kgp.XXXXXXXXXXXX)
        commandFile=$(mktemp /tmp/kgp.command.XXXXXXXXXXXX)
        resultFile=$(mktemp /tmp/kgp.result.XXXXXXXXXXXX)

        # Key bindings
        declare -A commands
        commands+=(
                ["edit"]="ctrl-e"
                ["delete"]="ctrl-t"
                ["describe"]="ctrl-b"
                ["logs"]="ctrl-l"
        )

        kubectl get $1 |
                sk -m --ansi --preview "{
                        kubectl describe $1 {1} > $tempFile &&
                                lines=\$(echo \$(wc -l < $tempFile)) &&
                                eventsLine=\$(echo \$(wc -l < $tempFile) | grep -n 'Events:' | cut -d: -f 1) &&
                                bat $tempFile --line-range \$eventsLine:\$lines; 
                        less -e $tempFile;
                }" --bind "${commands[delete]}:execute(kubectl delete $1 {}),${commands[edit]}:execute(echo 'edit' > $commandFile; echo {} > $resultFile)+abort,${commands[describe]}:execute(echo 'describe' > $commandFile; echo {} > $resultFile)+abort,${commands[logs]}:execute(echo 'logs' > $commandFile; echo {} > $resultFile)+abort"

        # Cleanup temporary files
        exitCode=$(echo $?)
        rm $tempFile
        run=$(cat $commandFile)
        result=$(cat $resultFile | awk '{print $1}')
        rm $commandFile
        rm $resultFile

        # Handle commands after skim exits
        if [[ $exitCode -eq 130 ]]; then # Skim was aborted
                if [[ ! -z "$run" ]]; then
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
                                echo "Can't get logs for type $1"
                        fi
                fi
        fi
}

unalias kgp
unalias kgd
alias kgp="kubeFuzzy pods"
alias kgd="kubeFuzzy deployments"
