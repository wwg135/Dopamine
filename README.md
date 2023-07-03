# Dopamine (RootHide)

RootHide is a completely hidden rootless jailbreak solution without to inject/modify/patch/hook apps.

This project is the RootHide implementation based on Dopamine Jailbreak.


# Progress

- [x]  Remove fakelib
- [x]  Remove bind mount
- [x]  Remove system-wide dyld file patch
- [x]  Unsandbox systemhook.dylib before injected it
- [x]  Randomize systemhook.dylib file name
- [x]  Randomize the /var/jb/ fixed path
- [x]  Add jailbreak environment variable
- [x]  linker/loader works with randomized /var/jb/
- [x]  symlinks works with randomized /var/jb/
- [x]  Implements a middle layer to convert path
- [ ]  Adapt theos tools for RootHide
- [ ]  Original Rootless Compat Layer
- [x]  Adapt bootstraps for RootHide
- [x]  Adapt Sileo store for RootHide
- [x]  Adapt Zebra store for RootHide
- [x]  Adapt NewTerm app for RootHide
- [ ]  Adapt Filza manager for RootHide
- [ ]  Implement a blacklist selector app
- [ ]  Implement a /var/-files-clean app


# Credits

[@opa334](https://github.com/opa334/)

[@CRKatri](https://github.com/CRKatri)

[@procursus](https://github.com/ProcursusTeam/Procursus)

[@theos](https://github.com/theos/theos)


# Info

[theos_discord_server](https://theos.dev/discord)

[procursus_discord_server](https://discord.gg/QJDrrAJPDY)
