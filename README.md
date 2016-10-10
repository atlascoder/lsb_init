# lsb_init

lsb_init is a [gem][1] allowing to generate or remove [LSB Init][2] scripts (_aka system service startup-scripts_) for Ruby project.

A Ruby project, having a Gemfile with `gem 'lsb_init'`, can be ran as a system service.
It will start and stop automatically with hosting system.
___

## Installation

Just add `gem 'lsb_init'` to project's Gemfile and run `bundle install`.

After this you will be able to call `lsb_init_ruby` utility to manage start script. 
___

## Usage

The gem provides a command-line utility `lsb_init_ruby` for managing startup script.

The command `lsb_init_ruby` should be called from any location within ruby project's tree in  form:

```bash
lsb_init_ruby g|d [servicename]
```

`g` - generate and setup LSB Init scripts

`d`- delete LSB Init scripts

`servicename` - optional name of service. If omit, project's root folder name will be used as name for service.

***

## Integration into project

After call of `lsb_init_ruby g my_service` the module LsbInit::Main `../lsb_init/main.rb` will be created.
Put your points into provided methods:

`do_main` - is calling when service should starts (it corresponds to CLI command `service my_service start`)

`do_finish` - is calling when service should stop (it corresponds to CLI command `service my_service stop`)

`do_reload` - is calling when service should reload (it corresponds to CLI command `service my_service reload`)

<small>**Note**, that `do_reload` is not an equiv to CLI command `service my_service restart`. The `service my_service restart` actually equiv to `do_finish && do_main`.
LSB Init Actions provides special `service my_serive reload` command which usually used for manual call for soft reinitialization
of a service without fully reloading. Of course, its implementations lies on developer totally.</small>
___

#### Important!
_The generated script will **run service as user who was calling generating**!_

<u>_**Don't call generation command as root if you don't want to run service as root!**_</u>

***

#### Example

For a project at `/home/joe/my_service` (containing `/home/joe/my_service/Gemfile`)

Running `lsb_init_ruby g` form user __joe__ will do following:

1. defines root for the project as `/home/joe/my_service`
1. checks if `my_service` is unique service name at the system or fails otherwise
1. removes existing scripts for service `my_service`
1. creates folder `/home/joe/a_proj/lsb_init` if it doesn't exist
1. generates LSB Init compliant script at `/home/joe/a_proj/lsb_init/my_service`
1. checks if it was runned in RVM env and creates alias for current RVM with name `my_service` if true
1. sets first line to rvm-wrapper if RVM was found
1. moves `/home/joe/a_proj/lsb_init/my_service` to `/etc/init.d/my_service` using `sudo`
1. installs LSB Init scripts with default runlevels requirements (for ref. see [here][5])

**As results** there are installed scripts that starts and stops `my_service` with the hosting system.

Running `lsb_init_ruby d` from user __joe__ will perform aforementioned points from 1 to 3.

***

## Basic requirements
#### Work only in LSB-compliant systems

LSB ([Linux Standard Base][4]) is supported by several, but most popular, distributions of Linux.
Certified products may be found at [wiki][3], and particularly the are:
* Debian (and derivatives)
* Ubuntu
* RedHat (and derivatives)
* SUSE
* Mandriva
* ...

Please check if your system is LSB compliant before.

#### Requires root or appropriate sudoer

As far as the tool creates system-level scripts.

#### Customer's project should have **Gemfile** (should use the `bundler` gem) 

The `lsb_init` gem provides CLI utility `lsb_init_ruby` which is looking for the Gemfile to define the root-path of project.

The `lsb_init_ruby` performs search of Gemfile from the directory it was called and looks up by directory tree till found or got `/`.
It means that `lsb_init_ruby` will work properly even being ran from project's subdirectory.

Be sure that the current path is proper before running `lsb_init_ruby`, because **it generates LSB Init scripts for 
the the project's root when first facing of a Gemfile on its search going to the `/` path**.

***

[1]: https://rubygems.org "rubygem"
[2]: https://wiki.debian.org/LSBInitScripts "LSB Init Scripts"
[3]: https://en.wikipedia.org/wiki/Linux_Standard_Base "LSB Certified"
[4]: http://refspecs.linuxbase.org/lsb.shtml "Linux Base"
[5]: http://refspecs.linuxbase.org/LSB_5.0.0/LSB-Core-generic/LSB-Core-generic/iniscrptact.html "LSB Init Actions"