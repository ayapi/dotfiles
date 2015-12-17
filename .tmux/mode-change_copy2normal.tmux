#setenv TMUX_SELECTION 0
unbind-key -n S-Left
unbind-key -n S-Right
unbind-key -n S-Up
unbind-key -n S-Down
unbind-key -n S-Home
unbind-key -n S-End
unbind-key -n S-PPage
unbind-key -n S-NPage
unbind-key -n C-Up
unbind-key -n C-Down
unbind-key -n C-PPage
unbind-key -n C-NPage
unbind-key -n Left
unbind-key -n Right
unbind-key -n Up
unbind-key -n Down
unbind-key -n Home
unbind-key -n End
unbind-key -n PPage
unbind-key -n NPage
unbind-key -n Enter
unbind-key -n C-c
unbind-key -n Escape

# start copy-mode before scroll up
bind -n C-PPage \
  run ~/.tmux/commands/uim-fep-off\;\
  source-file ~/.tmux/mode-change_normal2copy.tmux\;\
  copy-mode -u\;\
  send-keys hR

bind -n C-Up \
  run ~/.tmux/commands/uim-fep-off\;\
  source-file ~/.tmux/mode-change_normal2copy.tmux\;\
  copy-mode\;\
  send-keys hR

source ~/.tmux/uim-fep-shift-arrow.tmux
