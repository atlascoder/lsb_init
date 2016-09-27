# lsb_init

lsb_init is a [gem][1] allowing to generate or remove [LSB Init][2] scripts (_aka system service startup-scripts_) for Ruby project.

A Ruby project, having a Gemfile with `gem 'lsb_init'`, can be ran as a system service.
It will start and stop automatically with hosting system.
___

## Installation

Just add `gem 'lsb_init'` to project's Gemfile and run `bundle install`.
___

## Usage

The gem provides a command-line utility `lsb_init_ruby`.

The command `lsb_init_ruby` should be called from any location within ruby project's tree in  form:

`lsb_init_ruby g|d [servicename]`

`g` - generate LSB Init scripts
`d` - delete LSB Init scripts
`servicename` - optional name of service. If omit, project's root folder name will be used as name for service.
___

## Integration into project

After call of `lsb_init_ruby g ...` the module LsbInit::Main `../lsb_init/main.rb` will be created.
Put your points into provided methods:

`do_main` - is calling when service should starts (it corresponds to CLI command `service xxx start`)
`do_finish` - is calling when service should stop (it corresponds to CLI command `service xxx stop`)
`do_reload` - is colling when service should reload (it corresponds to CLI command `service xxx reload`)

Note, that `do_reload` is separate call and it does not an equiv to CLI command `service xxx restart`.

The `service xxx restart` actually equiv to `do_finish && do_main`.

LSB Init Actions provides special `service xxx reload` command which usually used for manual call for soft reinitialization
of a service without fully reloading. Of course, implementations lies on developer totally.
___

#### Important note!
**the generated script will run service from user name used while generation!**

_**Don't call generation command as root if you don't want to run service as root!**_

#### Examples

For a project at `/home/joe/a_proj` (containing `/home/joe/a_proj/Gemfile`)

Running `lsb_init_ruby g` form user __joe__ will do following:

1. defines root for the project as `/home/joe/a_proj`
2. checks if `a_proj` is unique service name at the system or fails otherwise

3. removes folder `/home/joe/a_proj/lsb_init` if it exists
4. removes existing scripts for service `a_proj`

5. generates `/home/joe/a_proj/lsb_init` and `/home/joe/a_proj/lsb_init/runner` folders
6. generates LSB Init compliant script at `/home/joe/a_proj/lsb_init/runner/a_proj`
7. copies `/home/joe/a_proj/lsb_init/runner/a_proj` to `/etc/init.d/a_proj` using `sudo`
8. installs LSB Init scripts with default runlevels requirements (for ref. see [here][5])

**Results:** installed scripts that starts and stops servoce with the hosting system.

Running `lsb_init_ruby d` from user __joe__ will perform aforementioned points from 1 to 4.

## Basic requirements
#### Works only in LSB-compliant systems

LSB ([Linux Standard Base][4]) is supported by several, but most popular, distributions of Linux.
Certified products may be found at [wiki][3], and particularly the are:
* Debian (and derivatives)
* Ubuntu
* RedHat (and derivatives)
* SUSE
* Mandriva
* ...

Please check if your system is LSB compliant before.

#### Running under root or sudo

As far as the tool creates system-level scripts - it requires for root access.

#### Customer's project should have **Gemfile** (should use the `bundler` gem) 

The lsb_init gem provides CLI utility `lsb_init_ruby` which is looking for the Gemfile to define the root-path of project.

The `lsb_init_ruby` performs search of Gemfile from the directory it was called and looks up by directory tree till found or got `/`.
It means that `lsb_init_ruby` will work properly even being ran from project's subdirectory.

Be sure that the current path is proper before running `lsb_init_ruby`, because **it generates LSB Init scripts for 
the the project's root when first facing of a Gemfile on its search going to the `/` path**.

###

[1]: https://rubygems.org "rubygem"
[2]: https://wiki.debian.org/LSBInitScripts "LSB Init Scripts"
[3]: https://en.wikipedia.org/wiki/Linux_Standard_Base "LSB Certified"
[4]: http://refspecs.linuxbase.org/lsb.shtml "Linux Base"
[5]: http://refspecs.linuxbase.org/LSB_5.0.0/LSB-Core-generic/LSB-Core-generic/iniscrptact.html "LSB Init Actions"