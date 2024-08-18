# Risk Fortress 2 Mapper's Introduction

Creating maps for Risk Fortress is a very simple process at its core. The most that is needed for a basic functional map is a navigation mesh 
and some Teleporter spawn points. However, Risk Fortress provides a vast set of different entities and functionality to use to create more advanced maps
that are able to utilize their own form of logic, such as custom objectives, secret areas that reward players with loot, and more. This is all provided
by the `rf2.fgd` file, which exposes the functionality of many of the custom entities that the plugin utilizes to the Hammer Editor, to be placed inside of your map.
<br/><br/> 

Before we get started, let's go through a quick tutorial on how to install custom .fgd files inside of Hammer. I'll be using 
[Hammer++](https://ficool2.github.io/HammerPlusPlus-Website/) specifically in this guide,
which I highly recommend using over the stock Hammer Editor if you aren't already.
<br/><br/>

### Adding the custom FGD file to Hammer
1. Download `rf2.fgd` from the Releases page in this repository.
2. Go to your Team Fortress 2 installation folder. Place `rf2.fgd` inside of the `Team Fortress 2/bin/` directory.
3. Start up Hammer. Go to **Tools -> Options**.
4. Next to the **Game Data files** list, click **Add**. Find and open `rf2.fgd` in the prompt, in the directory that you placed it in.
5. Restart Hammer. The next time you open Hammer you should see some new entities in the entity list, prefixed with `rf2_`.
