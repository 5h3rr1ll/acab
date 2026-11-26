# Renders docs/demo.gif — run from the repo root:  vhs docs/demo.tape
# Uses fake configs in docs/demo-aws/ (never your real ~/.aws).

Output docs/demo.gif
Require fzf

Set Shell "bash"
Set FontSize 16
Set Width 1100
Set Height 560
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 60ms

Hide
Type `export PATH=$PWD:$PATH HOME=$(mktemp -d) PS1='$ ' && cp -R docs/demo-aws $HOME/.aws && cd $HOME && eval "$(acab init bash)" && clear`
Enter
Sleep 500ms
Show

# 1. Fully interactive: pick a config file, then a profile
Type "acab"
Sleep 400ms
Enter
Sleep 1200ms
Type "work"
Sleep 900ms
Enter
Sleep 1200ms
Type "prod"
Sleep 1500ms
Enter
Sleep 1500ms
Type 'echo "$AWS_PROFILE"'
Enter
Sleep 1500ms

Type "clear"
Enter

# 2. Direct: config + account ID
Type "acab work 7777"
Sleep 400ms
Enter
Sleep 1800ms

# 3. Direct: role_arn profiles in another config file
Type "acab client prod"
Sleep 400ms
Enter
Sleep 2500ms
