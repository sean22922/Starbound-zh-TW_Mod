a SBVN game file should be a JSON object specifying:
  * displayConfig - an object with settings that are global to the game
  * titleScene - an object describing a scene (see below) for which options will be added programmatically
  * entryScene - a string scene name for where the game begins
  * scenes - an object describing all non-title scenes in the game

displayConfig should specify:
  * title - to be displayed in the window's title bar
  * subtitle - to be displayed in the window's title bar
  * textColor - color for the main textbox
  * selFormat - a format string for selected options
  * unselFormat - a format string for unselected options
  * textRate - text scroll rate in characters per second

a scene is an object with the following fields, all optional:
  * background - image to display in the background
  * foreground - image to display in the foreground (e.g. character)
  * foregroundFrame - optional frame within the foreground image. changing frames will not trigger a transition
  * text - text that will scroll into the textbox
  * continue - scene transition (described below) to transition to directly (without options)
  * options - list of selectable options for scenes to transition to
    each option is an array with elements:
      1. display text for the option
      2. scene transition (described below)
      3. optional, a list of flag conditions (described below) that must be true for the option to appear
      4. optional, a list of flag operations (described below) to perform when the option is selected
 if no options or continue are specified, the scene is considered to be an endpoint and
 will lead back to the title screen

a flag condition is a string containing:
  * a flag name
  * an operator (<, >, or =)
  * an integer value
  examples:
    "love>2"
    "hate=0"

a flag operation is a string containing:
  * a flag name
  * an operator (+, -, or =)
  * an integer value
  examples:
    "love+2"
    "hate=100"

a scene transition is:
  * a string, name of the scene to transition to when the option is selected
     -OR-
  * list of options which can be either a string, or a list of [flag condition, scene] to transition to different
    scenes based on flag state. the list will be processed in order
  example:
    [["love>9", "goodEnding"], ["love<0", "badEnding"], "neutralEnding"]
