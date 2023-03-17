# zsh-penmux

zsh-penmux is a session manager plugin for zsh. It is meant to be used for penetration testing sessions and tracking the terminal sessions to be used in reports.

Features:

- Managing tmux sessions for logging purpose (sessions, tasks, actions)
- Layouts for session creation
- Easy session logging by using [tmux-logging-extended](https://github.com/mfulz/tmux-logging-extended)

## Demo

![gif](https://github.com/mfulz/zsh-penmux/raw/master/docs/example1.gif)

## Getting Started

### Requirements

- zsh
- git
- tmux
- [tmux-logging-extended](https://github.com/mfulz/tmux-logging-extended)

### Installation

#### oh-my-zsh

Clone this repositoy into the oh-my-zsh plugins folder:

```
cd ~/.oh-my-zsh/custom/plugins
git clone https://github.com/mfulz/tmux-logging-extended
```

Then add the following to your zshrc:

```zsh
plugins+=(zsh-penmux)
```

#### Manual

*TODO*

### Usage

*TODO*
