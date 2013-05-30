# `irb -r ./startup.rb`
# Just an easy delete & reinstall mechanism

# Remove all previous gem installations
`gem uninstall -Ia jst-parser`
`rm -rf pkg/`

## Install local source code as gem
`rake install`

## Require the gem
require 'jst'