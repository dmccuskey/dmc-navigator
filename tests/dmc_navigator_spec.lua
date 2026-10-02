--====================================================================--
-- tests/dmc_navigator_spec.lua
--
-- unit tests for dmc_navigator, with a stand-in display, Runtime
-- and clock; slides run a frame at a time, as in Solar2D
-- run with tests/run_unit.sh
--====================================================================--


module( ..., package.seeall )


--====================================================================--
--== Setup

local FRAME = 16 -- ms

-- the clock: time moves only in frame()

local now = 0
system.getTimer = function() return now end

local function addListener( list, name, l )
	list[name] = list[name] or {}
	table.insert( list[name], l )
end

local function removeListener( list, name, l )
	for i, x in ipairs( list[name] or {} ) do
		if x==l then table.remove( list[name], i ) ; return end
	end
end

local runtime_listeners = {}
_G.Runtime = {
	addEventListener=function( self, name, l ) addListener( runtime_listeners, name, l ) end,
	removeEventListener=function( self, name, l ) removeListener( runtime_listeners, name, l ) end,
}

local function countEnterFrame() return #( runtime_listeners.enterFrame or {} ) end

-- display objects: a group's children are placed in it,
-- and its listeners get the events dispatched to it

local methods = {}
local META = { __index=methods }

local function newObject( props )
	local o = setmetatable( { x=0, y=0, isVisible=true, numChildren=0, listeners={} }, META )
	for k, v in pairs( props or {} ) do o[k] = v end
	return o
end

function methods:insert( o ) o.parent = self end
function methods:remove( o ) o.parent = nil end
function methods:removeSelf() self.removed = true end
function methods:setFillColor() end
function methods:addEventListener( name, l ) addListener( self.listeners, name, l ) end
function methods:removeEventListener( name, l ) removeListener( self.listeners, name, l ) end
function methods:dispatchEvent( event )
	for _, l in ipairs( self.listeners[event.name] or {} ) do
		if type( l )=='function' then l( event ) else l[event.name]( l, event ) end
	end
end

_G.display = {
	newGroup=function() return newObject() end,
	newRect=function( x, y, w, h ) return newObject{ x=x, y=y, width=w, height=h } end,
}

-- run n frames of 'enterFrame'
local function frame( n )
	for _ = 1, n or 1 do
		now = now + FRAME
		local copy = {}
		for i, l in ipairs( runtime_listeners.enterFrame or {} ) do copy[i] = l end
		for _, l in ipairs( copy ) do l{ name='enterFrame', time=now } end
	end
end

-- frames for ms milliseconds
local function wait( ms ) frame( math.ceil( ms/FRAME ) ) end

local SLIDE = 400 -- Navigator.TRANSITION_TIME

-- the boot and dmc_objects set their own globals; snapshot after them
pcall( function() require( 'dmc_corona_boot' ) end )
require 'dmc_objects'
local globals = {}
for k in pairs( _G ) do globals[k] = true end

local Navigator = require 'dmc_navigator'

local nav, removed

local function newView( name ) return newObject{ name=name } end

local function names( list )
	local t = {}
	for i, v in ipairs( list ) do t[i] = v.name end
	return table.concat( t, ' ' )
end

-- a stand-in nav bar; prefix '' for the current DMC-Corona-UI, '_' for 2015
local function newNavBar( prefix )
	local bar = { calls={} }
	local function trans( name )
		return function( percent ) table.insert( bar.calls, name..' '..percent ) end
	end
	bar[prefix..'pushNavItemGetTransition'] = function( self, item ) return trans( 'push' ) end
	bar[prefix..'popNavItemGetTransition'] = function( self ) return trans( 'pop' ) end
	return bar
end

local function newNavView( name )
	return newObject{ name=name, nav_bar_item={ backButton={} } }
end


function setup()
	now = 0
	runtime_listeners = {}
	removed = {}
	nav = Navigator:new{ width=320, height=480 }
	nav:addEventListener( nav.EVENT, function( e )
		if e.type==nav.REMOVED_VIEW then table.insert( removed, e.view ) end
	end )
end

function teardown()
	nav:removeSelf()
end


--====================================================================--
--== Tests


function test_version()
	assert_equal( '0.4.0', Navigator.VERSION )
end

function test_no_new_globals()
	for k in pairs( _G ) do
		assert_true( globals[k], "new global: "..tostring( k ) )
	end
end

function test_root_view_appears_at_once()
	local v1 = newView( 'v1' )
	nav:pushView( v1 )
	assert_equal( v1, nav.top_view )
	assert_equal( 'v1', names( nav.views ) )
	assert_true( v1.isVisible )
	assert_equal( 0, v1.x )
	assert_equal( 0, countEnterFrame() )
end

function test_push_slides_in()
	local v1, v2 = newView( 'v1' ), newView( 'v2' )
	nav:pushView( v1 )
	nav:pushView( v2 )
	assert_equal( 1, countEnterFrame() )
	wait( SLIDE/2 )
	assert_true( v2.x>0 and v2.x<320, "v2 mid-slide" )
	wait( SLIDE )
	assert_equal( v2, nav.top_view )
	assert_equal( 'v1 v2', names( nav.views ) )
	assert_true( v2.isVisible )
	assert_false( v1.isVisible )
	assert_equal( 0, countEnterFrame() )
end

function test_views_is_a_copy()
	nav:pushView( newView( 'v1' ) )
	local list = nav.views
	table.insert( list, newView( 'x' ) )
	assert_equal( 'v1', names( nav.views ) )
end

-- the important bug: the first slide's listener ran forever,
-- pushing its view each frame
function test_push_during_slide()
	local v1, v2, v3 = newView( 'v1' ), newView( 'v2' ), newView( 'v3' )
	nav:pushView( v1 )
	nav:pushView( v2 )
	wait( 100 )
	nav:pushView( v3 )
	assert_equal( 'v1 v2', names( nav.views ), "v2's slide finished" )
	wait( 1400 )
	assert_equal( 'v1 v2 v3', names( nav.views ) )
	assert_equal( v3, nav.top_view )
	assert_true( v3.isVisible )
	assert_false( v2.isVisible )
	assert_equal( 0, countEnterFrame() )
end

function test_pop_during_push()
	local v1, v2 = newView( 'v1' ), newView( 'v2' )
	nav:pushView( v1 )
	nav:pushView( v2 )
	wait( 100 )
	assert_true( nav:popViewAnimated() )
	wait( 1400 )
	assert_equal( 'v1', names( nav.views ) )
	assert_equal( v1, nav.top_view )
	assert_equal( 'v2', names( removed ) )
	assert_true( v1.isVisible )
	assert_equal( 0, v1.x )
	assert_equal( 0, countEnterFrame() )
end

function test_pop_slides_out()
	local v1, v2 = newView( 'v1' ), newView( 'v2' )
	nav:pushView( v1 )
	nav:pushView( v2 )
	wait( SLIDE+50 )
	assert_true( nav:popViewAnimated() )
	assert_equal( 0, #removed, "removed when the slide ends" )
	wait( SLIDE+50 )
	assert_equal( 'v2', names( removed ) )
	assert_equal( v1, nav.top_view )
	assert_true( v1.isVisible )
	assert_false( v2.isVisible )
	assert_equal( 0, countEnterFrame() )
end

-- the example removes each view in its handler: nothing may touch it after
function test_view_removed_in_handler()
	local v1, v2 = newView( 'v1' ), newView( 'v2' )
	nav:addEventListener( nav.EVENT, function( e )
		if e.type==nav.REMOVED_VIEW then
			setmetatable( e.view, { __index=function() error( "used after removal" ) end,
				__newindex=function() error( "used after removal" ) end } )
			for k in pairs( e.view ) do rawset( e.view, k, nil ) end
		end
	end )
	nav:pushView( v1 )
	nav:pushView( v2 )
	wait( SLIDE+50 )
	nav:popViewAnimated()
	wait( SLIDE+50 )
	assert_equal( v1, nav.top_view )
	assert_true( v1.isVisible )
end

function test_pop_at_root_does_nothing()
	assert_false( nav:popViewAnimated(), "empty" )
	local v1 = newView( 'v1' )
	nav:pushView( v1 )
	assert_false( nav:popViewAnimated(), "root on top" )
	wait( SLIDE+50 )
	assert_equal( 'v1', names( nav.views ) )
	assert_equal( 0, #removed )
	assert_true( v1.isVisible )
end

function test_pop_to_root()
	local v = {}
	for i = 1, 4 do v[i] = newView( 'v'..i ) ; nav:pushView( v[i] ) end
	assert_equal( 'v1 v2 v3', names( nav.views ), "v4 still sliding in" )
	assert_true( nav:popToRoot() )
	assert_equal( 'v3 v2', names( removed ), "the middle ones at once" )
	wait( SLIDE+50 )
	assert_equal( 'v3 v2 v4', names( removed ) )
	assert_equal( 'v1', names( nav.views ) )
	assert_equal( v[1], nav.top_view )
	assert_true( v[1].isVisible )
	assert_false( nav:popToRoot() )
	assert_equal( 0, countEnterFrame() )
end

function test_pop_to_root_not_animated()
	nav:pushView( newView( 'v1' ) )
	nav:pushView( newView( 'v2' ) )
	assert_true( nav:popToRoot{ animate=false } )
	assert_equal( 'v1', names( nav.views ) )
	assert_equal( 0, countEnterFrame() )
end

function test_cleanUp_during_slide()
	nav:pushView( newView( 'v1' ) )
	nav:pushView( newView( 'v2' ) )
	wait( 100 )
	nav:cleanUp()
	assert_equal( 'v2 v1', names( removed ) )
	assert_equal( 0, #nav.views )
	assert_nil( nav.top_view )
	assert_equal( 0, countEnterFrame() )
	-- the next push is a new root
	local v3 = newView( 'v3' )
	nav:pushView( v3 )
	assert_equal( 0, countEnterFrame() )
	assert_true( v3.isVisible )
end

function test_nav_bar_current_names()
	local bar = newNavBar( '' )
	nav.nav_bar = bar
	local v1, v2 = newNavView( 'v1' ), newNavView( 'v2' )
	nav:pushView( v1 )
	nav:pushView( v2 )
	wait( SLIDE+50 )
	nav:popViewAnimated()
	wait( SLIDE+50 )
	assert_equal( 'push 100', bar.calls[1] )
	assert_equal( 'pop 0', bar.calls[#bar.calls] )
	assert_equal( v1.nav_bar_item.backButton.onRelease, v2.nav_bar_item.backButton.onRelease )
	assert_not_nil( v2.nav_bar_item.backButton.onRelease )
end

function test_nav_bar_2015_names()
	local bar = newNavBar( '_' )
	nav.nav_bar = bar
	nav:pushView( newNavView( 'v1' ) )
	nav:pushView( newNavView( 'v2' ) )
	wait( SLIDE+50 )
	nav:popViewAnimated()
	wait( SLIDE+50 )
	assert_equal( 'push 100', bar.calls[1] )
	assert_equal( 'pop 0', bar.calls[#bar.calls] )
end

function test_back_button_pops()
	nav.nav_bar = newNavBar( '' )
	local v2 = newNavView( 'v2' )
	nav:pushView( newNavView( 'v1' ) )
	nav:pushView( v2 )
	wait( SLIDE+50 )
	v2.nav_bar_item.backButton.onRelease{}
	wait( SLIDE+50 )
	assert_equal( 'v1', names( nav.views ) )
end
