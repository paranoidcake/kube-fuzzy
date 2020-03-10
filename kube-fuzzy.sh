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
    DIR=$(echo $DIR | sed "s/\/kube-fuzzy.sh$//")

    # Temporary files for reading / writing data from skim
    local tempFile=$(mktemp /tmp/kube_fuzzy.XXXXXXXXXXXX)
    local actionFile=$(mktemp /tmp/kube_fuzzy.command.XXXXXXXXXXXX)
    echo "none" > $actionFile

    # Read key bindings from the 'any' file
    declare -A keybinds
    while IFS= read -r line; do
        if [[ -z $line || "$(printf '%s' "$line" | cut -c1)" == '#' ]]; then
            continue
        else
            local action="$(printf '%s' $line | cut -d '=' -f 1)"
            if [[ -z ${keybinds[$action]} ]]; then
                keybinds[$action]="$(printf '%s' $line | cut -d '=' -f 2)"
            else
                echo "Conflicting keybind for $action found in file '$DIR/keybinds/any'!" >&2
                return 5
            fi
        fi
    done < $DIR/keybinds/any

    # And again for the current resource
    while IFS= read -r line; do
        if [[ -z $line || "$(printf '%s' "$line" | cut -c1)" == '#' ]]; then
            continue
        else
            local action="$(printf '%s' $line | cut -d '=' -f 1)"
            if [[ -z ${keybinds[$action]} ]]; then
                keybinds[$action]="$(printf '%s' $line | cut -d '=' -f 2)"
            else
                echo "Conflicting keybind for $action found in file '$DIR/keybinds/$resource!'" >&2
                return 5
            fi
        fi
    done < $DIR/keybinds/$resource

    # Generate string of binds based on keybinds and functions found in actions.sh
    local actions
    while IFS= read; do
        if [[ ! -z ${keybinds[$REPLY]} ]]; then
            actions+=$(echo "${keybinds[$REPLY]}:execute(echo 'kube_$REPLY' > $actionFile),")
        fi
    done <<< "$(grep ^function $DIR/actions.sh | awk '{ print $2 }' | sed "s/()$//" | sed "s/kube_//")"

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

function kube_define() {
    resource="${1}"
    binds="${2}"

    if test -n "$BASH" ; then DIR=$BASH_SOURCE
    elif test -n "$TMOUT"; then DIR=${.sh.file}
    elif test -n "$ZSH_NAME" ; then DIR=${(%):-%x}
    elif test ${0##*/} = dash; then x=$(lsof -p $$ -Fn0 | tail -1); DIR=${x#n}
    else DIR=$0
    fi
    DIR=$(echo $DIR | sed "s/\/kube-fuzzy.sh$//")

    if [[ ! -f $DIR/keybinds/$resource ]]; then
        echo "No definitions found for type $resource"
        echo "Generating..."
        touch "$DIR/keybinds/$resource"
    else
        echo "The following definitions were found for type $resource:"
        echo -e "$(cat "$DIR/keybinds/$resource")"
        echo "Append or overwrite? [a/o] (Any other key will abort)"
        read op
        case $op in
            o | O)
                echo "Overwriting..."
                echo -e "$(echo $binds | tr " " "\n")" > $DIR/keybinds/$resource
                ;;
            a | A)
                echo "Appending..."
                echo -e "$(echo $binds | tr " " "\n")" >> $DIR/keybinds/$resource
                ;;
            *)
                echo "Aborting..."
                return 0
                ;;
        esac
        echo "New keybinds are now:"
        echo -e "$(cat "$DIR/keybinds/$resource")"
    fi

    unset op
}

alias kgp="kube_fuzzy pods --events"
alias kgd="kube_fuzzy deployments --events"
alias kgs="kube_fuzzy services --events"
alias kgsec="kube_fuzzy secrets"
