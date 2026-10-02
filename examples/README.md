# Examples

Each folder is a complete Solar2D project with its own copy of the library: open its `main.lua` in the Solar2D Simulator.

| | |
|---|---|
| <img src="screenshots/dmc-navigator-simple.png" width="240" alt="dmc-navigator-simple: the Sea image, a blue square, under a title bar with a Back button; an All Galleries button below"> | **dmc-navigator-simple**: browse galleries of images (colored squares). Tap a gallery, then an image: each page slides in from the right, and the title bar above the navigator shows its title. Back pops a page (`popViewAnimated()`), All Galleries goes back to the first one (`popToRoot()`), and the app removes each view in the `REMOVED_VIEW` handler. The pages are [dmc-objects](https://github.com/dmccuskey/dmc-objects) components, in `views/`. |
