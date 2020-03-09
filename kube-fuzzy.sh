#!/bin/bash

function kube_fuzzy () {
    # Handle arguments / flags
    resource=${1}
    eventsFlag=false

    if [[ -z $resource ]]; then
        echo "Error: A resource is required" >&2
        return 1
    fi
    if [[ ${2} == "--events" ]] || [[ ${2} == "-e" ]]; then
        if [[ ! $(command -v bat) ]]; then
            echo "Warning: --events flag was used but bat is not installed!" >&2
        fi
        eventsFlag=true
    fi

    # Temporary files for reading / writing data from skim
    local tempFile=$(mktemp /tmp/kube_fuzzy.XXXXXXXXXXXX)
    local actionFile=$(mktemp /tmp/kube_fuzzy.command.XXXXXXXXXXXX)
    echo "none" > $actionFile

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

    # Declare actions to be inputted to --bind
    actions=$(
echo -e "${commands[none]}:execute(echo 'none' > $actionFile)
${commands[delete]}:execute(kubectl delete ${resource} {1})
${commands[edit]}:execute(echo 'edit' > $actionFile)
${commands[describe]}:execute(echo 'describe' > $actionFile)
${commands[logs]}:execute(echo 'logs' > $actionFile)
${commands[containers]}:execute(echo 'containers' > $actionFile)
${commands[decode]}:execute(echo 'decode' > $actionFile)" | tr '\n' ',')

    # Launch sk and store the output
    local result=$(kubectl get $resource |
    sk -m --ansi --preview "{
        echo \"Last selected action was: \$(cat $actionFile) (updates with preview window)\";
        echo '';
        kubectl describe ${resource} {1} > $tempFile;
        if [[ $eventsFlag == true ]]; then
            lines=\$(echo \$(wc -l < $tempFile));
            eventsLine=\$(cat $tempFile | grep -n 'Events:' | cut -d: -f 1);
            echo \"-------------------------------------------------------------\"
            bat $tempFile --line-range \$eventsLine:\$lines 
            echo \"-------------------------------------------------------------\"
        fi
        less -e $tempFile;
        }" --bind "ctrl-c:abort,$actions") # Binding to capture ctrl-c so that temp files are properly cleaned

    if [[ -z $result ]]; then       # No selection made, cleanup and return
        rm $tempFile
        rm $actionFile
        echo "Aborted" >&2
        return 4
    fi

    # Cleanup temporary files, retrieve the action to run
    rm $tempFile
    local action=$(cat $actionFile)
    rm $actionFile

    # Execute selected action
    if [[ "$action" != "none" ]]; then
        local result=$(echo $result | awk '{ print $1 }' | tr '\n' ' ' | sed 's/.$//') # Format result to be usable for multiline inputs

        # Global actions
        case $action in
            edit)
                kubectl edit $resource $(echo $result);;
            describe)
                kubectl describe $resource $(echo $result);;
            *)
                # Check for type specific actions
                case $resource in      
                    pods)
                        case $action in
                            logs)
                                if [[ $result == *" "* ]]; then
                                    echo "WIP: Can't currently log multiple pods" >&2
                                    return 6
                                else
                                    kubectl logs $(echo $result)
                                fi
                                ;;
                            containers)
                                if [[ $result == *" "* ]]; then
                                    echo "WIP: Can't currently handle multiple pods' containers" >&2
                                    return 6
                                else
                                    echo "Fetching containers..."
                                    local contNames=$(printf '%s\n' $(kubectl get pods $result -o jsonpath='{.spec.containers[*].name}'))
                                    local initContNames=$(printf '%s\n' $(kubectl get pods $result -o jsonpath='{.spec.initContainers[*].name}'))
                                    local finalContNames=""

                                    if [[ ! -z $contNames && ! -z $initContNames ]]; then
                                        local finalContNames="$contNames\n$initContNames"
                                    elif [[ ! -z $contNames ]]; then
                                        local finalContNames="$contNames"
                                    else
                                        local finalContNames="$initContNames"
                                    fi

                                    local logCont=$(echo -e $finalContNames | sk --ansi --preview "kubectl logs $result -c {}")
                                    if [[ ! -z $logCont ]]; then
                                        kubectl logs $result -c $logCont
                                    fi
                                fi
                                ;;
                            *)
                                echo "Error: Can't execute '${action}' on resource ${1}" >&2
                                return 5;;
                        esac;;
                    secrets)
                        case $action in
                            decode)
                                if [[ $result == *" "* ]]; then
                                    echo "WIP: Can't decode the data of multiple secrets"
                                    return 6
                                else
                                    toSplit=$(kubectl get secrets $(echo $result) -o jsonpath='{.data}')
                                    toSplit=$(echo $toSplit | cut -c 5- | sed 's/.$//')
                                    splitArr=($(echo "$toSplit" | tr ':' ' '))
                                    echo "Fetched values for $result:"
                                    echo "${splitArr[*]}"
                                    echo ''
                                    echo "Decoded values for $result:"
                                    count=0
                                    for item in ${splitArr[@]}; do
                                        if [[ ! $(( $count % 2 )) -eq 0 ]]; then
                                            echo $(echo $item | base64 -d)
                                        else
                                            printf "$item: "
                                        fi
                                        ((count++))
                                    done
                                fi
                                ;;
                            *)
                                echo "Error: Can't execute '${action}' on resource ${1}" >&2
                                return 5;;
                        esac;;
                    *)
                        echo "Error: Can't execute '${action}' on resource ${1}" >&2
                        return 5;;
                esac
        esac
    else    # Selection made with no command
        echo -e "$result"
    fi
}

alias kgp="kube_fuzzy pods --events"
alias kgd="kube_fuzzy deployments --events"
alias kgs="kube_fuzzy services --events"
alias kgsec="kube_fuzzy secrets"
