##
# ~/.bashrc: executed by bash(1) for non-login shells.
##

##
# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022
##

export TERM=xterm

##
# You may uncomment the following lines if you want `ls' to be colorized:
##

export LS_OPTIONS='--color=auto'
export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

##
# Aliases
##

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias ll='ls -ahlF --color --group-directories-first'

alias c='clear'
alias h='cd ~/'
alias hc='h && c'
alias back='cd $OLDPWD'

alias ff='find . -type f -name'
alias fd='find . -type d -name'

alias now='date +%T'

alias art='php artisan'
alias artisan='php artisan'

alias phpspec='vendor/bin/phpspec'
alias phpunit='vendor/bin/phpunit'

##
# Some more alias to avoid making mistakes:
##

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'