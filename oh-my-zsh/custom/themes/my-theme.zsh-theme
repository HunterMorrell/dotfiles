# primary prompt
PROMPT='$FG[237]------------------------------------------------------------%{$reset_color%}
$FG[032]┌─=[ %n@%m ]=[ %~\
$(git_prompt_info)\
$(git_prompt_status) $FG[032]]
$FG[032]└─%(!.#.»)%{$reset_color%} '


# color vars
eval my_orange='$FG[214]'

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX=" ]=[ $FG[078]"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="$my_orange*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$FG[032]%{$reset_color%}"

# Format for git_prompt_status()
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg_bold[green]%}+%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg_bold[blue]%}!%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg_bold[red]%}-%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg_bold[magenta]%}>%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg_bold[yellow]%}#%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[cyan]%}?%{$reset_color%}"
