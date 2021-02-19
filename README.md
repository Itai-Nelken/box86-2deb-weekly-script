# box86-2deb weekly script
 a script that automatically compiles and packages [box86](https://github.com/ptitSeb/box86) into a deb using [checkinstall](http://checkinstall.izto.org/).

to download and run:
### Please note that the scripts are built to work for my use case, you will have to tweak them so they work for you. 
```bash
cd Documents
git clone https://github.com/Itai-Nelken/box86-2deb-weekly-script.git
cd box86-2deb-weekly-script
sudo chmod +x start.sh
./start.sh
```
to view credits and other info, type: `./start.sh --about`. that will show the credits and some more info and exit.
to update the scripts, type: `./start.sh --update`
### Notes:
1) This script only works on **armhf** Linux Debian and Debian based OS's.
2) it's **VERY IMPORTANT** to git clone and run the scripts from **there folder** in **~/Documents**!!!
3) by default, this script will compile and package box86 on Thursday every week until stopped.<br>to change to different day, change the `Thu` in line 99 of `box86-2deb-auto.sh` to the first 3 letters of any other day, 
its important that the first letter is capitalized. you can use the table bellow:<br>

| day "code" | day       |
|  :---:     | :---:     |
| Sun        | Sunday    |
| Mon        | Monsay    |
| Tue        | Tuesday   |
| Wed        | Wednesday |
| Thu        | Thursday  |
| Fri        | Friday    |
| Sat        | Staurday  |

4) The script will only create and move files in `~/Documents/box86-auto-build`, the final builds will be in `~/Documents/box86-auto-build/debs` in both tar.xz archives and uncompressed folders. the name of each folder & archive is the date in which they where built in YY/MM/DD format, for example: `2021-02-19` folder and `2021-02-19.tar.xz` archive.<br>Inside each folder (and archive) there is the box86 deb named box86_tagname-1_armhf (for example: `box86_0.2.1-1_armhf.deb`) and a text file named `sha1.txt` containing the sha1 (git commit "code") for the box86 version in the deb (for example: `ade7d82e`).
5) to see my notes for stuff I might need/use/will use, read [NOTES.md](NOTES.md)

## License
[GNU GPL v3](https://github.com/Itai-Nelken/box86-2deb-weekly-script/blob/main/LICENSE)
