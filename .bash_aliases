# ~/.bash_aliases

# general
alias ls='ls --color=auto'
alias ..='cd ..'
alias ls='lsd --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias rm='rm -i'  # ask before every removal
alias cls='clear'
alias clr='clear'
alias Q='exit'
alias ll='ls -lhF --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias rs='source ~/.bashrc'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# programs
alias iF='sudo iftop'
alias hogs='sudo nethogs -C'
alias gs='git status'
alias bt='btop'
alias ht='htop'
alias ytF='yt-dlp -f bestvideo+bestaudio'


# ubuntu/debian
alias uP='sudo apt update -y; sudo apt upgrade -y; sudo apt autoremove -y; rustup update'

# Git
