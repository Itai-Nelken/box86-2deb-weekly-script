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
2) by default, this script will compile and package box86 on Thursday every week until stopped.<br>to change to fifferent day, change the `Thu` in line 99 of `box86-2deb-auto.sh` to the first 3 letters of any other day, you can use the table bellow:<br>
| day "code" | day       |
|  :---:     | :---:     |
| Sun        | Sunday    |
| Mon        | Monsay    |
| Tue        | Tuesday   |
| Wed        | Wednesday |
| Thu        | Thursday  |
| Fri        | Friday    |
| Sat        | Staurday  |
its important that the first letter is capitalized.


## License
[GNU GPL v3](https://github.com/Itai-Nelken/box86-2deb-weekly-script/blob/main/LICENSE)
