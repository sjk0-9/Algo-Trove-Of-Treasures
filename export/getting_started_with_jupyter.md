# Getting started with Jupyter

There are a tonne of different ways to install jupyter.
This is the way I've got mine installed.
If you don't really care about package management,
then feel free to just skip straight to [package installation](#Package-Installation).

I use a Mac and this method has some Mac dependencies that won't work on Windows.
It may work on Linux... but I haven't tested it.
There are corresponding alternatives for both those OSes that shouldn't be too hard to find.
But if you're getting lost, maybe just follow the official docs.
In fact.
Maybe just ignore me and follow the official docs regardless of your OS.
The only benefit of doing it this way, is it keeps all the mess of packages you need to install and python versions you need to track in once place.

This guide is written with the assumption that you're a complete novice with the command line.
If you're familiar with tools like `zsh`, `vim` and the like, I assume you'll already know what parts do and don't apply to you.
If you've never used it before, great.
The best thing is, once you've finished this part, you really won't have to use it again for any of this stuff.
Hit `cmd+space`, type "terminal", and enter.
Congratulations. You've entered the matrix!

## Setup environment using pyenv

Python has really bad package and version management out of the box.
Like not good at all.

Instead there's a bunch of helpful tools available that can help you overcome that.
For this, we'll use homebrew, pyenv and virtualenv.

If you're on a mac, you'll need to at least have xcode tools, which are the minimum requirements for developing software. Open a terminal and run:

```bash
xcode-select --install
```

If you don't have homebrew installed, follow the instructions [here](https://brew.sh/).
Homebrew just makes installing, updating and maintaing stuff for software development (and other things) sooo much easier.

With homebrew installed, open up your terminal, and install pyenv, pyenv-virtualenv, and a bunch of prerequisites that pyenv sometimes requires.

```bash
brew update
brew install pyenv pyenv-virtualenv openssl readline sqlite3 xz zlib
```

Open `~/.bashrc` in your command line with the command `nano ~/.bashrc`.
Use your keyboard to navigate to the very end of the file (if there is any file) and add the following:

```bash
alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
eval "$(pyenv virtualenv-init -)"
```

This just sets up some stuff required each time we re-boot the commandline.

To save and exit, hit `ctrl+O` and then `ctrl+X`.

Quit and re-open your terminal for the changes to take effect.

You now have pyenv and virtualenv.
These will allow you to create custom environments where you can install everything you need for your project, and keep track of the correct version of python, without needing to mess with anything on a system level.
It's nice.
Trust me.

Now we'll create an environment for our Algorand experiments in jupyter.

```bash
pyenv virtualenv 3.9 Algorand-In-Jupyter
```

This downloads python version 3.9 (most recent as of writing), and sets up a virtual environment called "Algorand-In-Jupyter" where we can use it.

To activate the environment,

```bash
pyenv activate Alogrand-In-Jupyter
```

To check we're set up, call:

```bash
python --version
```

And it should output something like `Python 3.9.5` (the last number may be different).

You'll need to re-activate it every time you restart your terminal.
Though there are ways to get it to run automatically.
But now we're in, we can install everything else we need.

## Package Installation

If you've jumped straight to here without setting up the virtual environment, you'll need to explicitly call `pip3` wherever it says `pip`.
If you're using the environment we set up, we've already specified that we're using python 3, so no need.

Install the Jupyter lab and the Algorand SDK using pythons package manager pip.

```
pip install jupyterlab py-algorand-sdk
```

If you want to do stuff todo with NFTs, then you may also want to interact with IPFS. In these guides I'll use Pinanta, which has a helpful HTTP API we can access by the requests library.

```
pip install requests
```

Simple as that.

## Running

To begin, create and enter into new directory where we're going to save our experiments.

```bash
mkdir algo-experiments
cd algo-experiments
```

And then start up jupyter

```bash
jupyter lab
```

Your default webbrowser should start up, with the jupyter app ready to go!
Time to get excited!