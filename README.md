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
- jq
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

### 1. Commands for `penmux`

| Command    | Description |
|------------|-------------|
| `session`  | Managing penmux sessions |
| `task`     | Managing penmux tasks    |
| `action`   | Managing penmux actions  |
| `logger`   | Managing logging         |

#### 1.1 Commands for `session`

| Command    | Description | Options |
|------------|-------------|---------|
| `create`   | Will create a new penmux session | `--session`,`--work_dir`,`--no_log`,`--action`,`--task`,`--layout` |
| `attach`   | Will attach to a penmux session | `--session` |
| `destroy`  | Will end a penmux session | `--session` |
| `list`     | List existing penmux sessions | (None) |

#### 1.2 Commands for `task`

| Command    | Description | Options |
|------------|-------------|---------|
| `create`   | Will create a new task | `--session`,`--task`,`--action` |
| `rename`   | Will rename a task | `--session`,`--task`,`--task_id`,`--new_name` |

#### 1.3 Commands for `action`

| Command    | Description | Options |
|------------|-------------|---------|
| `create`   | Will create a new action | `--session`,`--task`,`--action` |
| `rename`   | Will rename a task | `--session`,`--task`,`--task_id`,`--new_name`,`--no_log`,`-b`,`-d`,`-f`,`-h`,`-v` |

#### 1.4 Commands for `logger`

| Command    | Description | Options |
|------------|-------------|---------|
| `add`      | Will add an action to the logger | `--session`,`--task`,`--task_id`,`--action`,`--action_id` |
| `remove`   | Will remove an action from the logger | `--session`,`--task`,`--task_id`,`--action`,`--action_id` |
| `start`    | Will start logging | `--session` |
| `stop`     | Will stop logging | `--session` |
| `toggle`   | Will toggle logging | `--session` |


