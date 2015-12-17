# select&copy behavior like MS cmd.exe
# rectangle selection
# shift+arrow -> select
# enter -> copy

set-window-option -g mode-keys emacs

unbind -t emacs-copy C-c
unbind -t emacs-copy C-v
unbind -t emacs-copy M-v
unbind -t emacs-copy Space
unbind -t emacs-copy C-e
unbind -t emacs-copy C-a
unbind -t emacs-copy Escape
unbind -t emacs-copy C-Space
unbind -t emacs-copy b
unbind -t emacs-copy c
unbind -t emacs-copy x
unbind -t emacs-copy u
unbind -t emacs-copy d
unbind -t emacs-copy l
unbind -t emacs-copy h
unbind -t emacs-copy e
unbind -t emacs-copy k
unbind -t emacs-copy j

unbind -t emacs-copy S-Left
unbind -t emacs-copy S-Right
unbind -t emacs-copy S-Up
unbind -t emacs-copy S-Down
unbind -t emacs-copy S-Home
unbind -t emacs-copy S-End
unbind -t emacs-copy S-PPage
unbind -t emacs-copy S-NPage

unbind -t emacs-copy Left
unbind -t emacs-copy Right
unbind -t emacs-copy Up
unbind -t emacs-copy Down
unbind -t emacs-copy Home
unbind -t emacs-copy End
unbind -t emacs-copy PPage
unbind -t emacs-copy NPage
unbind -t emacs-copy Enter

source ~/.tmux/mode-change_copy2normal.tmux

# copy-mode keys for controlling from global keybinds
bind -t emacs-copy b	begin-selection
bind -t emacs-copy x	clear-selection
bind -t emacs-copy c	copy-selection -x
bind -t emacs-copy u	cursor-up
bind -t emacs-copy d	cursor-down
bind -t emacs-copy l	cursor-left
bind -t emacs-copy r	cursor-right
bind -t emacs-copy h	start-of-line
bind -t emacs-copy e	end-of-line
bind -t emacs-copy k	page-up
bind -t emacs-copy j	page-down
bind -t emacs-copy p	copy-pipe "~/.tmux/commands/copy"
