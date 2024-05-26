

          ,      ,$$$$$.  ,$;  ,$.   ,$;,$$$.
         .;,    ;$$,,,    ;$'  ;$'   ;$$   ;$
      '";$:""'   '""$$;   $$   $$    $$    $$
         ;     '$$$$$'    '$$$$$$   ,$'   ,$'

                 ,$
     ,$$$$$.  ,$$$$$$'   ,$$$,$;   ,$;,$$;
    ;$$,,,      ;$'     ;$   ;$'   ;$$
     '""$$;     $$      $$   $$    $$
    '$$$$$'    ,$'      '$$$$$$.  ,$'


      vanilla lua config for neovim ~

      space-key mappings
      VCS integration
      straightforward config

      [ Github ]
      https://github.com/szym-mie/sunstar-nvim

    # Installation

      nvim config can be found in:
      - Windows                      - Unix
        %HOME%\AppData\Local\nvim      ~/.config/nvim

      1. Backup your current config, by moving it somewhere else.
      
      2. Clone this repo to nvim directory:
         git clone git@github.com:szym-mie/sunstar-nvim.git <nvim-config>

      3. Run neovim - a plugin manager will be installed, along with the
         default suite of plugins.


    # Features
      
      1. Ergonomic mappings (space-keys) - instead of typing commands,
         use space and combination of keys to perform actions.
         To see available keystreaks, hit space and wait.

      2. VCS integration - support for git and svn, with builtin
         commands for the most common actions. You don't need to leave
         your editor to commit, stash, fetch or checkout.

      3. Update at startup - a quick check at the startup of neovim,
         to ensure all plugins are up to date. It is performed 
         asynchronously, so your startup time doesn't suffer.

      4. Classic init file - you can now install any lsp server,
         configure any plugin you want - just edit init.lua.


    # Configuration

      1. You can easily install themes and other plugins, while in neovim 
         hit [Space-f-e-a] to edit file 'plugins.txt'.
         All new plugins will be installed at next startup.

      2. Select theme interactively by [Space-T].

      3. sunstar config contains some specific options in a more convient
         format. edit it by [Space-f-e-c].
