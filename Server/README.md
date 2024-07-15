# Poshcord-C2 server

**SYNOPSIS**

This script creates a GUI for receiving the info stream from one Poshcord-C2 client.

**USAGE**
1. Replace TOKEN_1_HERE with the main token. (the token used for the client)
2. Create a SECOND bot with the same permissions as the client bot and add it to the same server.
3. Replace TOKEN_2_HERE with the token you just created (used for sending messages like a user)
4. Run the script to create the Control GUI

**IMPORTANT**
- Both bots must only be in ONE Server ONLY.
- Run This Script AFTER starting the client session
- Only one set of client channels can be in the server (delete closed sessions in discord after use).
- Add ->   -ip your.ip.address.or.domain -port 8080 to the 'session command input' box before running StartUVNC
- get UVNC listener here - https://github.com/beigeworm/assets/raw/main/uvnc-server.zip
  
![Screenshot_1](https://github.com/user-attachments/assets/1725becb-c357-486b-8c07-4580e6fa4ad2)
