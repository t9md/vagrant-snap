[NOTE] Not work for Vagrant v1.0 above.
==================================
Since I haven't used Vagrant in my daily work and I didn't have free time, I haven't managed this plugin over 2 years.  
So don't use this plugin for Vagrant v1.0.  Sorry.  You can use [sahara](https://github.com/jedi4ever/sahara) instead for similar functionality.
  
P.S.  
Recently I came back to OSS world as my own hobby, I might update this plugin if time available.  

What's this?
==================================
vagrant snapshot management plugin
can handle multi-vm environment.

## Install

    gem install vagrant-snap

## Following commands are added

    Tasks:
      vagrant snap back                   # back to current snapshot
      vagrant snap delete SNAP_NAME       # delete snapshot
      vagrant snap go SNAP_NAME           # go to specified snapshot
      vagrant snap help [COMMAND]         # Describe subcommands or one specific subcommand
      vagrant snap list                   # list snapshot
      vagrant snap take [NAME] [-d DESC]  # take snapshot

## Screen capture

![vagrant_snap_list](https://github.com/t9md/vagrant-snap/raw/master/misc/vagrant_snap_list.png)

## Example

In actual example, current snapshot is highlighted with yellow ANSI color.

    t510 dev/vagtest02% vagrant snap take
    [db]
    0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    [web]
    0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    t510 dev/vagtest02% 
    t510 [1] dev/vagtest02% vagrant snap list    
    [db]
    +-db-01 [ 16 seconds ]
    [web]
    +-web-01 [ 14 seconds ]
    t510 dev/vagtest02% vagrant snap take -d "2nd snap"
    [db]
    0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    [web]
    0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    t510 dev/vagtest02% vagrant snap list 
    [db]
    +-db-01 [ 48 seconds ]
        +-db-02 [ 10 seconds ] 2nd snap
    [web]
    +-web-01 [ 47 seconds ]
        +-web-02 [ 8 seconds ] 2nd snap
    t510 dev/vagtest02% vagrant snap go web-01 web                 
    [web]
    0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    Restoring snapshot 283d90aa-ef75-4316-a847-e04961c2ec26
    0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    Waiting for the VM to power on...
    VM has been successfully started.
    t510 dev/vagtest02% vagrant snap list 
    [db]
    +-db-01 [ 1 minute ]
        +-db-02 [ 40 seconds ] 2nd snap
    [web]
    +-web-01 [ 1 minute ]
        +-web-02 [ 38 seconds ] 2nd snap
    t510 dev/vagtest02% 


## Similar projects
* [sahara](https://github.com/jedi4ever/sahara)
* [vagrant-vbox-snapshot](https://github.com/dergachev/vagrant-vbox-snapshot) (compatible with Vagrant 1.1+)
* https://gist.github.com/tombh/5142237 (compatible with Vagrant 1.0.4 - 1.0.7)

## Other
I intentionally avoided naming this plugin as 'vagrant-snapshot', because I believe Vagrant author  
implement snap shot management feature and want to use 'snapshot' as command name.

## VM configuration
In my experience, to avoid `VERR_SSM_LOAD_CONFIG_MISMATCH` error when restoreing snaphot,  
disable `USB controller` and `absolte pointing device`.
