run "tmux setenv TMUX_SELECTION 0"
bind -n Enter \
  source-file ~/.tmux/mode-change_copy2normal.tmux\;\
  send-keys p

bind -n C-c \
  source-file ~/.tmux/mode-change_copy2normal.tmux\;\
  send-keys p

bind -n Escape \
  source-file ~/.tmux/mode-change_copy2normal.tmux\;\
  send-keys q

bind -n S-Left	run "~/.tmux/commands/shift-arrow l"
bind -n S-Right	run "~/.tmux/commands/shift-arrow r"
bind -n S-Up	run "~/.tmux/commands/shift-arrow u"
bind -n S-Down	run "~/.tmux/commands/shift-arrow d"
bind -n S-Home	run "~/.tmux/commands/shift-arrow h"
bind -n S-End	run "~/.tmux/commands/shift-arrow e"
bind -n S-PPage	run "~/.tmux/commands/shift-arrow k"
bind -n S-NPage	run "~/.tmux/commands/shift-arrow j"
bind -n Left	run "~/.tmux/commands/arrow l"
bind -n Right	run "~/.tmux/commands/arrow r"
bind -n Up	run "~/.tmux/commands/arrow u"
bind -n Down	run "~/.tmux/commands/arrow d"
bind -n Home	run "~/.tmux/commands/arrow h"
bind -n End	run "~/.tmux/commands/arrow e"
bind -n PPage	run "~/.tmux/commands/arrow k"
bind -n NPage	run "~/.tmux/commands/arrow j"
bind -n C-Up	run "~/.tmux/commands/arrow u"
bind -n C-Down	run "~/.tmux/commands/arrow d"
bind -n C-NPage	run "~/.tmux/commands/arrow j"
