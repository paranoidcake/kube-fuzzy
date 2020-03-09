#!/bin/bash

function kube_fuzzy () {
    # Handle arguments / flags
    resource=${1}
    eventsFlag=false

    if [[ -z $resource ]]; then
        echo "Error: A resource is required" >&2
        return 2
    fi
    if [[ ${2} == "--events" ]] || [[ ${2} == "-e" ]]; then
        if [[ ! $(command -v bat) ]]; then
            echo "Warning: --events flag was used but bat is not installed!" >&2
        fi
        eventsFlag=true
    fi

    # Get directory kube_fuzzy was cloned in (POSIX compliant I swear)
    if test -n "$BASH" ; then DIR=$BASH_SOURCE
    elif test -n "$TMOUT"; then DIR=${.sh.file}
    elif test -n "$ZSH_NAME" ; then DIR=${(%):-%x}
    elif test ${0##*/} = dash; then x=$(lsof -p $$ -Fn0 | tail -1); DIR=${x#n}
    else DIR=$0
    fi
    DIR=$(echo $DIR | sed "s/kube-fuzzy.sh$//")

    # Temporary files for reading / writing data from skim
    local tempFile=$(mktemp /tmp/kube_fuzzy.XXXXXXXXXXXX)
    local actionFile=$(mktemp /tmp/kube_fuzzy.command.XXXXXXXXXXXX)
    echo "none" > $actionFile

    # Key bindings
    declare -A keybinds
    keybinds+=(
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
echo -e "${keybind[none]}:execute(echo 'none' > $actionFile)
${keybind[delete]}:execute(echo 'kube_delete' > $actionFile)
${keybind[edit]}:execute(echo 'kube_edit' > $actionFile)
${keybind[describe]}:execute(echo 'kube_describe' > $actionFile)
${keybind[logs]}:execute(echo 'kube_logs' > $actionFile)
${keybind[containers]}:execute(echo 'kube_containers' > $actionFile)
${keybind[decode]}:execute(echo 'kube_decode' > $actionFile)" | tr '\n' ',')

    # Launch sk and store the output
    local result=$(kubectl get $resource |
    sk -m --ansi --preview "{
        echo \"Last selected action was: \$(cat $actionFile | sed s/kube_//) (updates with preview window)\";
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
        return 1
    fi

    # Cleanup temporary files, retrieve the action to run
    rm $tempFile
    local action=$(cat $actionFile)
    rm $actionFile

    # An action was selected
    if [[ "$action" != "none" ]]; then
        local result=$(echo $result | awk '{ print $1 }' | tr '\n' ' ' | sed 's/.$//') # Format result to be usable for multiline inputs

        # 
        $DIR/actions.sh "$action" "$resource" "$result"

        # Handle function exit codes
        local exit_code=$(echo $?)

        if [[ ! $exit_code -eq 0 ]]; then
            local fun_name=$(echo $action | sed "s/kube_//")
            if [[ $exit_code -eq 3 ]]; then
                echo "Action $fun_name incompatible with resource of type $resource" >&2
                return 3
            elif [[ exit_code -eq 4 ]]; then
                echo "Action $fun_name incompatible with multiple inputs" >&2
                return 4
            else
                return $exit_code
            fi
        fi
    else    # Selection made with no command
        echo -e "$result"
    fi
}

alias kgp="kube_fuzzy pods --events"
alias kgd="kube_fuzzy deployments --events"
alias kgs="kube_fuzzy services --events"
alias kgsec="kube_fuzzy secrets"
