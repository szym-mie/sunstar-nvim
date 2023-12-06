

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

      1. backup your current config, by moving it somewhere else.
      
      2. clone this repo to nvim directory:
         git clone git@github.com:szym-mie/sunstar-nvim.git <nvim-config>

      3. run neovim - a plugin manager will be installed, along with the
         default suite of plugins.


    # Features
      
      1. ergonomic mappings (space-keys) - instead of typing commands,
         use space and combination of keys to perform actions.
         to see available keystreaks, hit space and wait. you can check
         other branches in similar fashion as well.

      2. VCS integration - support for git and svn, with builtin
         commands for the most common actions. you don't need to leave
         your editor to commit, stash, fetch or checkout.

      3. update at startup - a quick check at the startup of neovim,
         to ensure all plugins are up to date. it is performed 
         asynchronously, so your startup time doesn't suffer.

      4. classic init file - you can now install any lsp server,
         configure any plugin you want - just edit init.lua.


    # Configuration

      1. you can easily install themes and other plugins, while in neovim 
         hit [Space-f-e-a] to edit file 'plugins.txt'.
         all new plugins will be installed at next startup.

      2. select theme interactively by [Space-T].

      3. sunstar config contains some specific options in a more convient
         format. edit it by [Space-f-e-c].
