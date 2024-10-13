# Private Server Setup Tutorial
This guide is for those who wish to set up a private Risk Fortress dedicated server for yourself or friends to join and play. A few things to note:
- Port forwarding or using a VPN service such as Hamachi is NOT required.
- Since the plugin can be very resource-intensive at times, you may want to host it on a separate machine from the one you plan to run TF2 with, or a machine that's powerful enough to host a dedicated server and run TF2 simultaneously without lagging issues.
- The server.cfg file is located in `tf/cfg/` in your dedicated server directory.

## Steps
1. If you haven't already, download and install SRCDS, MetaMod, SourceMod, the Risk Fortress plugin and any of its dependencies onto your server. This will not be covered here since it is outside the scope of this guide.
2. Make sure that ANYONE you plan on having connect to your server has ALL of the necessary maps, models, materials, and sounds in their `Team Fortress 2/tf/download/` directory! Failure to do this may cause connecting players to be stuck on the loading screen with prolonged download times, unless your server has a FastDL set up.
3. In the shortcut you use to run your server, add the `-enablefakeip` launch option.   
   **IMPORTANT: This will cause your server to show up in the community server browser! If you still want to keep your server private, set a password by adding this to your server.cfg file:**
   `sv_password "yourpasswordhere"`

4. Run the server. Connecting to the server via Steam friends list will NOT work. There are three ways for players to connect to the server:
   - **(Host only)** Go to the LAN tab in the Community Server Browser and you should be able to see your server.
   - The host should type the `status` command in the server console. The server's IP/port will be the first address next to the `udp/ip` field. Give this to your friends and tell them to enter in the console: `connect <ip:port>; password <password>` WITHOUT the <>.
   - In your server.cfg file, give your server a unique tag by adding `sv_tags "yourtagherecanbeanything"`. Tell your friends to search for this tag in the Internet tab in the server browser using the tags field.
