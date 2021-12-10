# TODO

- Add variation compression and jump into variation when making a move
- Add multiple games support
- Add i18n
  - Maybe remove all multi-line hints from strings, as they aren't saved into PO files correctly
  - Set `DefaultCaption = True` for every TButtonPanel (for i18n).
- Add an option to declare draw by arbitrary number of moves (50, 100, 128, 256)
  - Or, upgrade to the modern rules: fivefold repetition + 75 move rule
- Process `info string` responses from the engine
- Use UCI `debug` option
- Do not start and kill engines so much when starting and changing games
  - Maybe reuse the engines between different games
  - Keep engine options when re-creating a game
- Improve board piece rendering (especially on Win32 and Qt widgetsets)
- Allow to configure timeouts for engines
- Reduce needless refreshes in the start of the game for board and notation
- Optimize undo & redo
  - Make VisualChessNotation render faster in this case
  - Do not save the whole lists, save just the difference
- Fix the bug that undo continues after releasing the key, when it was held for a large amount of time
- Allow to pass command-line options for engines
- Add Winboard/XBoard engines support
- Fix diacritics and strange unicode rendering issues in the notation
  - Rewrite calculation of on-screen character length
  - Maybe do not use just one char to determine it, but use two or more char
  - Another option is to switch to a native richtext view and forget about these issues
- Remove deprecated parts
  - Remove PseudoDocking and replace with AnchorDocking
- Port the changes made in BattleField back to Chess256

## Potentally obsolete or unclear issues

- Improve MoveParsing to better handle lower case and upper case (make it much more flexible)
- Remove the Debug Console
  - It's hidden by default now, should we finally remove it?
