- to login to git with your github account (to for example push the finished archives to a github repo):
    * ~~download and install [github-cli](https://github.com/cli/cli/releases/latest).~~
    * ~~type: `gh auth login` and follow the steps to login.~~
    * `git config --global user.email "you@example.com"`
    * `git config --global user.name "User-Name"`
- to run the script in background and keep it running even after logging out of a ssh session:
    ### Method 1
    * `nohup ./start.sh &`
    * all the output will be in a file called `nohup.out` (I think the file called **nohup**.out).
    ### Method 2 (better one probably)
    * install screen (first time only): `sudo apt install screen`.
    * run screen: `screen`
    * run the script.
    * [ctrl + a + d], it should say detached [something].
    * `screen -r` to return
    #### to run multiple commands with screen:
    * `screen -S [screenname]` and `screen -r [screenname]`.
