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

        kubectl edit pods $(kubectl get pods |
        fzf -m --preview "{
                kubectl describe pod {1} > /tmp/kgpPrev;
                lines=\$(echo \$(wc -l < /tmp/kgpPrev));
                echo -------------------------------------------------------
                eventsLine=\$(cat /tmp/kgpPrev | grep -n 'Events:' | cut -d: -f 1);
                bat /tmp/kgpPrev --line-range \$eventsLine:\$lines
                echo -------------------------------------------------------
                less /tmp/kgpPrev
        };" | awk '{ print $1 }')
        rm /tmp/kgpPrev
}


unalias kgd
function kgd () {
        if [ ! -f /tmp/kgdPrev ]; then
                mktemp /tmp/kgdPrev >/dev/null
        fi

        eventsLine=0
        lines=0

        kubectl edit deployments $(kubectl get deployments |
        fzf -m --preview "{
                kubectl describe deployments {1} > /tmp/kgdPrev;
                lines=\$(echo \$(wc -l < /tmp/kgdPrev));
                echo -------------------------------------------------------
                eventsLine=\$(cat /tmp/kgdPrev | grep -n 'Events:' | cut -d: -f 1);
                bat /tmp/kgdPrev --line-range \$eventsLine:\$lines
                echo -------------------------------------------------------
                less /tmp/kgdPrev
        };" | awk '{ print $1 }')
        rm /tmp/kgdPrev
}