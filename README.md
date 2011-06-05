What's this?
==================================
vagrant snapshot management plugin

## Install

    gem install vagrant-snap

## Following commands are added

    Tasks:
      vagrant snap back              # back to current snapshot
      vagrant snap delete SNAP_NAME  # delete snapshot
      vagrant snap go SNAP_NAME      # go to specified snapshot
      vagrant snap help [COMMAND]    # Describe subcommands or one specific subcommand
      vagrant snap list              # list snapshot
      vagrant snap take [desc]       # take snapshot

## Limitation

Currently multi-vm environment is not supported

## Similar project

[sahara](https://github.com/jedi4ever/sahara)

## Other
I intentionally avoid naming this plugin as 'vagrant-snapshot', because I believe Vagrant author  
implement snap shot management feature and want to use 'snapshot' as command name.

