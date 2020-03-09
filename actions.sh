#!/bin/bash
# 
# Actions to be paired with kube_fuzzy.sh
# 

function kube_delete () {
    resource="$1"
    pods="$2"
    kubectl delete "$resource" "$result"
}

function kube_edit() {
    resource="$1"
    result="$2"
    kubectl edit "$resource" "$result"
}

function kube_describe() {
    resource="$1"
    result="$2"
    kubectl describe "$resource" "$result"
}

function kube_logs() {
    resource="$1"
    result="$2"
    if [[ $resource == "pods" ]]; then
        if [[ $result == *" "* ]]; then
            echo "WIP: Can't currently log multiple pods" >&2
            return 4
        else
            kubectl logs $(echo $result)
        fi
    else
        return 3
    fi
}

function kube_containers() {
    resource="$1"
    result="$2"

    if [[ $resource == "pods" ]]; then
        if [[ $result == *" "* ]]; then
            echo "WIP: Can't currently handle multiple pods' containers" >&2
            return 4
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
        
            local logCont=$(echo -e "$finalContNames" | sk --ansi --preview "kubectl logs $result -c {}")
            if [[ ! -z $logCont ]]; then
                kubectl logs $result -c $logCont
            fi
        fi
    else
        return 3
    fi
}

function kube_decode() {
    resource="$1"
    result="$2"

    if [[ $resource == "secrets" ]]; then
        if [[ $result == *" "* ]]; then
            echo "WIP: Can't decode the data of multiple secrets" >&2
            return 4
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
    else
        return 3
    fi
}

"$@" # Take a function name as parameter to execute
