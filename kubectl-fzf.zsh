#
# Dependencies: bat (https://github.com/sharkdp/bat)
#               fzf (https://github.com/junegunn/fzf)
#

unalias kgp
function kgp () {
        if [ ! -f /tmp/kgpPrev ]; then
                mktemp /tmp/kgpPrev >/dev/null
        fi

        eventsLine=0
        lines=0

        # TODO: Use to highlight the Events: section of text
        # highlighting=""
        # 
        # count=\$eventsLine
        # for line in {\$eventsLine..\$((\$lines+1))}; do
        #         highlighting+=\"-H \$count\ "
        #         count=\$((\$count+1))
        # done

        result=$(kubectl get pods |
        fzf -m --preview "{
                kubectl describe pod {1} > /tmp/kgpPrev;
                lines=\$(echo \$(wc -l < /tmp/kgpPrev));
                echo -------------------------------------------------------
                eventsLine=\$(cat /tmp/kgpPrev | grep -n 'Events:' | cut -d: -f 1);
                bat /tmp/kgpPrev --line-range \$eventsLine:\$lines
                echo -------------------------------------------------------
                less -e /tmp/kgpPrev
        };" | awk '{ print $1 }')
        
        if [ ! -z "$result" ]; then
                kubectl edit pods $result
        fi

        rm /tmp/kgpPrev
}


unalias kgd
function kgd () {
        if [ ! -f /tmp/kgdPrev ]; then
                mktemp /tmp/kgdPrev >/dev/null
        fi

        eventsLine=0
        lines=0

        # TODO: Use to highlight the Events: section of text
        # highlighting=""
        # 
        # count=\$eventsLine
        # for line in {\$eventsLine..\$((\$lines+1))}; do
        #         highlighting+=\"-H \$count\ "
        #         count=\$((\$count+1))
        # done

        result=$(kubectl get deployments |
        fzf -m --preview "{
                kubectl describe deployments {1} > /tmp/kgdPrev;
                lines=\$(echo \$(wc -l < /tmp/kgdPrev));
                echo -------------------------------------------------------
                eventsLine=\$(cat /tmp/kgdPrev | grep -n 'Events:' | cut -d: -f 1);
                bat /tmp/kgdPrev --line-range \$eventsLine:\$lines
                echo -------------------------------------------------------
                less -e /tmp/kgdPrev
        };" | awk '{ print $1 }')

        if [ ! -z "$result" ]; then
                kubectl edit deployments $result
        fi

        rm /tmp/kgdPrev
}
