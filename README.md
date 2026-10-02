# dmc-navigator

Stack screens in a Solar2D (formerly Corona SDK) app and slide between them, like a phone's navigation controller.

dmc-navigator keeps a stack of views: push a view and it slides in from the right over the current one; pop it and it slides back out, and the navigator tells you to remove it:

```lua
local Navigator = require 'dmc_corona.dmc_navigator'

local navigator = Navigator:new{ width=display.contentWidth, height=display.contentHeight }
navigator.x = display.contentCenterX

navigator:pushView( listView )     -- the first view: shown at once
navigator:pushView( detailView )   -- slides in from the right
navigator:popViewAnimated()        -- slides back out; REMOVED_VIEW event
```

## Features

- A stack of views with push, pop and pop to root, the first view shown without animation
- A tap during a slide is safe: the running slide finishes at once, then the new one starts
- A slide transition: the new view comes in from the right, the old one drifts a quarter of the width to the left
- Views are any display object (a group, an image) or a [dmc-objects](https://github.com/dmccuskey/dmc-objects) component
- An event when a popped view can be removed, so the app decides how to dispose of it
- An optional nav bar that moves along with the views (from DMC-Corona-UI)
- MIT licensed

## Quick Start

The following code will get you up and running in about 10 minutes in the Solar2D Simulator on macOS or Windows. It makes an app of colored pages: tap a page to push the next one, tap Back to pop it.

Prerequisites: the [Solar2D](https://solar2d.com/) Simulator and a copy of this repository (`git clone https://github.com/dmccuskey/dmc-navigator.git`, or download the ZIP from GitHub).

### 1. Copy the Library into Your Project

Copy these from this repository into the root of your project folder:

```text
dmc_corona_boot.lua     loader for the DMC libraries
dmc_corona.cfg          configuration
dmc_corona/             dmc-navigator and the libraries it uses
```

**Going further:** keep the libraries in a subfolder, or combine several DMC libraries ([dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md)).

### 2. Push Pages

Create `main.lua` in the project folder:

```lua
local Navigator = require 'dmc_corona.dmc_navigator'

local W, H = display.contentWidth, display.contentHeight
local COLORS = { {0.2,0.4,0.8}, {0.2,0.6,0.4}, {0.8,0.5,0.2}, {0.6,0.3,0.6} }

local navigator = Navigator:new{ width=W, height=H }
navigator.x, navigator.y = W*0.5, 0

local top = 1 -- the number of the page on top
local newPage

newPage = function( number )
	local page = display.newGroup()

	local bg = display.newRect( page, 0, H*0.5, W, H )
	bg:setFillColor( unpack( COLORS[ (number-1) % #COLORS + 1 ] ) )
	display.newText( page, "Page " .. number, 0, H*0.4, native.systemFont, 64 )
	display.newText( page, "tap for the next page", 0, H*0.5, native.systemFont, 32 )

	bg:addEventListener( 'tap', function()
		top = number + 1
		navigator:pushView( newPage( top ) )
		return true
	end )

	return page
end

navigator:pushView( newPage( 1 ) )
```

Open the project in the Simulator. It shows a blue "Page 1". Click it: a green "Page 2" slides in from the right. Each click pushes another page.

If the console shows `module 'dmc_corona.dmc_navigator' not found` instead, `dmc_corona/` is missing from the root of the project folder.

The navigator's origin is its top center, so each page is drawn around `x = 0`, from `y = 0` down. The first view pushed is shown at once; later ones slide in over 400 ms. A tap during a slide finishes that slide at once, then starts the next.

### 3. Go Back

Add this to the end of `main.lua`:

```lua
local back = display.newText( "< Back", 90, 60, native.systemFont, 40 )
back:addEventListener( 'tap', function()
	navigator:popViewAnimated()
	return true
end )

navigator:addEventListener( navigator.EVENT, function( event )
	if event.type == navigator.REMOVED_VIEW then
		print( "removed page " .. top )
		event.view:removeSelf()
		top = top - 1
	end
end )
```

The Simulator restarts the app when the file is saved. Push a few pages, then click Back: the top page slides out to the right and the one below comes back. After two pages and two Backs, the console shows:

```text
removed page 3
removed page 2
```

`popViewAnimated()` hides the popped view and sends `REMOVED_VIEW` when the slide ends; removing the view is up to you. On Page 1, Back does nothing: the first view stays.

For a fuller app, with a title bar and pop to root, see the [example](examples/README.md).

To update, copy `dmc_corona_boot.lua` and `dmc_corona/` again from the newer version. Keep your own `dmc_corona.cfg` if you have changed it.

## Reference

`require 'dmc_corona.dmc_navigator'` returns the `Navigator` class, a [dmc-objects](https://github.com/dmccuskey/dmc-objects) `ComponentBase`: a display group you position with `x` and `y` and remove with `removeSelf()`. `Navigator.VERSION` is the module's version (`"0.4.0"`).

A push or pop while a slide runs first finishes that slide at once (as if its time were up), then does its own, so no call is lost.

### `Navigator:new( params )`

| param | default | effect |
|---|---|---|
| `width`, `height` | required | the navigator's size; `width` sets how far views slide |
| `transition_time` | `400` (`Navigator.TRANSITION_TIME`) | the slide's length, in milliseconds |

The navigator's origin is its top center: a view at `x = 0` is centered, and its top is at `y = 0`. The navigator doesn't clip: a view larger than it, or one mid-slide, shows outside it.

### `navigator:pushView( view, params )`

Adds `view` to the navigator and makes it the top view. `view` is a display object, or a component with a `view` or `display` property (that one is inserted). The first view pushed is shown at once; later ones slide in unless `params.animate` is `false`. The view below is hidden when the slide ends (hidden objects get no touches). The view joins `navigator.views` when its slide ends.

### `navigator:popViewAnimated()`

Slides the top view out to the right and shows the one below, then hides the popped view and dispatches `REMOVED_VIEW` with it. The navigator keeps no reference to it; remove it (`view:removeSelf()`) or keep it to push again. Returns `true`, or `false` when the first view is on top: the first view is never popped.

### `navigator:popToRoot( params )`

Goes back to the first view: the views between it and the top one are removed at once (a `REMOVED_VIEW` for each, from the top down), then the top view slides out as in `popViewAnimated()`, or goes at once if `params.animate` is `false`. Returns `true`, or `false` when the first view is on top.

### `navigator.top_view`, `navigator.views`

`top_view` is the view on top, or `nil` before the first push. `views` is a copy of the stack as a list, the first view first; a view sliding in joins it when its slide ends, and one sliding out leaves it then.

### `navigator:cleanUp()`

Finishes a running slide and pops every view, dispatching `REMOVED_VIEW` for each, top first. The next push is a new first view. Call it before `navigator:removeSelf()`, so the views are yours to remove.

### Events

Listen with `navigator:addEventListener( navigator.EVENT, handler )` (`'dmc-navigator-event'`). The handler gets an event with:

| field | value |
|---|---|
| `type` | `navigator.REMOVED_VIEW` (`'removed-view-event'`) |
| `view` | the view popped; the navigator is done with it, so the handler may remove it |
| `target` | the navigator |

### `navigator.nav_bar`

Sets a nav bar to move with the views. The navigator calls its `pushNavItemGetTransition( item, params )` and `popNavItemGetTransition( params )` (the NavBar of the current DMC-Corona-UI), or the same names with a leading underscore (its 2015 version), each returning a function of the slide's percent. Each pushed view needs a `nav_bar_item` with a `backButton`, whose `onRelease` the navigator sets to `popViewAnimated()`.

## Configuration

The `[DMC_NAVIGATOR]` section of `dmc_corona.cfg` (see [dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md) for the file's format):

| key | values | default | effect |
|---|---|---|---|
| `DEBUG_ACTIVE:BOOL` | `true`, `false` | `false` | fills the navigator's area in light green, to see where it is |

The `dmc_corona.cfg` in this repository has the section with the key commented out.

## Known Issues

- With a nav bar, `popToRoot()` slides out the second nav item's title, not the top one's: the nav bar has no pop to root, so the navigator pops its items one at a time, the last one animated.
- The nav bar hasn't been tested with the current DMC-Corona-UI, whose own NavigationControl does the same job as dmc-navigator.

Fixed issues are listed in the [CHANGELOG](CHANGELOG.md).

## Development

Only `dmc_corona/dmc_navigator.lua` is written in this repository. The rest of `dmc_corona/` and `dmc_corona_boot.lua` (and their copies in the example) are generated from [dmc-objects](https://github.com/dmccuskey/dmc-objects), [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) and [dmc-corona-boot](https://github.com/dmccuskey/dmc-corona-boot); fix them there, then rebuild. The copies are made by Snakemake from sibling checkouts (`../dmc-objects`, `../DMC-Corona-Library` for the shared rules, and so on). From this repository's root folder:

```sh
snakemake --cores 1 build_all
```

The tests are in `tests/dmc_navigator_spec.lua` ([lunatest](https://github.com/silentbicycle/lunatest)). Run them with plain Lua 5.1, with stand-ins for the Solar2D globals they touch (display objects, `Runtime`, `system.getTimer()`; slides run a frame at a time); it needs the `dkjson` rock:

```sh
tests/run_unit.sh
```

Then check the [example](examples/README.md) in the Solar2D Simulator: push pages, tap Back and All Galleries, and tap again during a slide.

## License

dmc-navigator is released under the [MIT License](LICENSE).
