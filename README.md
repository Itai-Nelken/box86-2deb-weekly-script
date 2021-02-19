# box86-2deb weekly script
 a script that automatically compiles and packages [box86](https://github.com/ptitSeb/box86) into a deb using checkinstall.

to download and run:
```bash
git clone https://github.com/Itai-Nelken/box86-2deb-weekly-script
cd box86-2deb-weekly-script
sudo chmod +x start.sh
./start.sh
```
### Notes:
1) This script only works on **armhf** Linux Debian and Debian based OS's.
2) by default, this script will compile and package box86 on Thursday every week until stopped.<br>to change to different day, change the `Thu` in line 99 of `box86-2deb-auto.sh` to the first 3 letters of any other day, 
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

3) The script will only create and move files in `~/Documents/box86-auto-build`, the final builds will be in `~/Documents/box86-auto-build/debs` in both tar.xz archives and uncompressed folders. the name of each folder & archive is the date in which they where built in YY/MM/DD format, for example: `2021-02-19` folder and `2021-02-19.tar.xz` archive.<br>Inside each folder (and archive) there is the box86 deb named box86_tagname-1_armhf (for example: `box86_0.2.1-1_armhf.deb`) and a text file named `sha1.txt` containing the sha1 (git commit "code") for the box86 version in the deb (for example: `ade7d82e`).

## License
[GNU GPL v3](https://github.com/Itai-Nelken/box86-2deb-weekly-script/blob/main/LICENSE)
