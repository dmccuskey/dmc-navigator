--====================================================================--
-- dmc_navigator.lua
--
-- Documentation:
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2013-2015 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
--== DMC Corona Library : DMC Navigator
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Support Functions


local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

	function _extend( fT, tT )

		for k,v in pairs( fT ) do

			if type( fT[ k ] ) == "table" and
				type( tT[ k ] ) == "table" then

				tT[ k ] = _extend( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == "table" then
				tT[ k ] = _extend( fT[ k ], {} )

			else
				tT[ k ] = v
			end
		end

		return tT
	end

	return _extend( fromTable, toTable )
end



--====================================================================--
--== Configuration


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona



--====================================================================--
--== DMC Navigator
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_navigator = dmc_lib_data.dmc_navigator or {}

local DMC_NAVIGATOR_DEFAULTS = {
	debug_active=false
}

local dmc_navigator_data = Utils.extend( dmc_lib_data.dmc_navigator, DMC_NAVIGATOR_DEFAULTS )
local Config = dmc_navigator_data



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local ComponentBase = Objects.ComponentBase



--====================================================================--
--== View Navigation Class
--====================================================================--


local Navigator = newClass( ComponentBase, {name="Base Navigator"} )

--== Class Constants

Navigator.TRANSITION_TIME = 250
Navigator.BUTTON_MARGIN = 8
Navigator.SLIDE_PADDING = 10

Navigator.BACKGROUND_COLOR = { 0.5, 0.5, 0, 1 }


--== Event Constants

Navigator.EVENT = 'view_navigator-event'

Navigator.SLIDES_ON_STAGE = 'slide_onstage_event'
Navigator.UI_TAPPED = 'Navigator_ui_tapped_event'
Navigator.CENTER_STAGE = 'slide_center_stage_event'
Navigator.FORWARD = 'forward'
Navigator.BACK = 'back'


--======================================================--
-- Start: Setup DMC Objects

function Navigator:__init__( params )
	-- print( "Navigator:__init__" )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	--== Sanity Check ==--

	if self.is_class then return end

	assert( params.width and params.height, "ERROR DMC Navigator: requires dimensions")


	--== Create Properties ==--

	self._width = params.width
	self._height = params.height

	self._views = params.slides or {} -- slide list, in order
	self._curr_slide = 1 -- showing current slide

	self._trans_time = self.TRANSITION_TIME

	self._canInteract = true
	self._isMoving = false -- flag, used to control dispatched events during touch move


	-- current, prev, next tweens
	self._tween = {
		c = nil,
		p = nil,
		n = nil
	} -- showing current slide

	--== Display Groups ==--

	--== Object References ==--

	self._primer = nil -- ref to display primer object

	self._onStage = params.onStageFunc -- reference to onStage callback

end
--[[
function Navigator:__undoInit__()
	--print( "Navigator:__undoInit__" )
	--==--
	self:superCall( "__undoInit__" )
end
--]]


function Navigator:__createView__()
	-- print( "Navigator:__createView__" )
	self:superCall( '__createView__' )
	--==--

	local o, p, dg, tmp  -- object, display group, tmp

	--== Setup display primer

	o = display.newRect( 0, 0, self._width, self._height )
	o:setFillColor(0,0,0,0)
	if Config.debug_active then
		o:setFillColor(0,255,0)
	end
	o.anchorX, o.anchorY = 0.5, 0
	o.x, o.y = 0,0


	self:insert( o )
	self._primer = o

	-- set the main object, after first child object
	self:setAnchor( self.TopCenterReferencePoint )
	self.x, self.y = 0,0

end
function Navigator:__undoCreateView__()
	-- print( "Navigator:__undoCreateView__" )

	local o

	o = self._primer
	o:removeSelf()
	self._primer = nil

	--==--
	self:superCall( '__undoCreateView__' )
end


-- __initComplete__()
--
--[[
function Navigator:__initComplete__()
	--print( "Navigator:__initComplete__" )
	self:superCall( "__initComplete__" )
	--==--
	-- self:addEventListener( "touch", self )
end
--]]
--[[
function Navigator:_undoInitComplete()
	--print( "Navigator:_undoInitComplete" )
	-- self:removeEventListener( "touch", self )
	--==--
	self:superCall( "_undoInitComplete" )
end
--]]

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function Navigator:viewIsVisible( value )
	-- print( "Navigator:viewIsVisible" )
	local o = self._current_view
	if o and o.viewIsVisible then o:viewIsVisible( value ) end
end

function Navigator:viewInMotion( value )
	-- print( "Navigator:viewInMotion" )
	local o = self._current_view
	if o and o.viewInMotion then o:viewInMotion( value ) end
end



function Navigator:addView( key, object, params )
	-- print( "Navigator:addView" )
	params = params or {}
	--==--

	local W, H = self._width, self._height
	local H_CENTER, V_CENTER = W*0.5, H*0.5

	self._views[ key ] = object
	object.isVisible = false

	local o = object
	if object.view then o = object.view end
	o.x, o.y = 0, 0

	self:insert( o )

end

function Navigator:removeView( key )
	-- print( "Navigator:removeView" )
	local o
	if key then
		o = self._views[ key ]
		self._views[ key ] = nil
	end

	return o
end

function Navigator:getView( key )
	-- print( "Navigator:getView ", key )
	return self._views[ key ]
end



function Navigator:gotoView( key, params )
	-- print( "Navigator:gotoView ", key )
	params = params or {}
	params.do_animation = params.do_animation or true
	params.direction = params.direction or Navigator.FORWARD
	--==--

	local W, H = self._width, self._height
	local H_CENTER, V_CENTER = W*0.5, H*0.5

	local o

	if self._current_view == nil or params.do_animation == false then
		-- have seen a view, but no transition necessary
		o = self._current_view
		if o then
			o.x, o.y = H_CENTER, 0
			o.isVisible = false
			if o then o.view_is_visible = false end
		end

		o = self:getView( key )
		o.x, o.y = 0, 0
		o.isVisible = true
		if o then o.view_is_visible = true end
		if o then o.view_on_stage = true end

		self._current_view = o

	else
		self:_transitionViews( key, params )

	end

	return self._current_view
end




--====================================================================--
--== Private Methods



function Navigator:_transitionViews( next_key, params )
	--print( "Navigator:_transitionViews" )

	local W, H = self._width, self._height
	local H_CENTER, V_CENTER = W*0.5, H*0.5

	local direction = params.direction
	local prev_view, next_view
	local time = self._trans_time

	prev_view = self._current_view
	next_view = self:getView( next_key )
	self._current_view = next_view


	-- remove previous view
	local step_3 = function()
		self.display.x, self.display.y = 0, 0

		prev_view.x, prev_view.y = H_CENTER, 0
		prev_view.isVisible = false
		if prev_view.viewOnStage then prev_view:viewOnStage( false ) end

		next_view.x, next_view.y = H_CENTER, 0
		next_view.isVisible = true
		if next_view.viewOnStage then next_view:viewOnStage( true ) end

	end

	-- transition both views
	local step_2 = function()

		local s2_c = function()
			if prev_view.viewInMotion then prev_view:viewInMotion( false ) end
			if prev_view.viewIsVisible then prev_view:viewIsVisible( false ) end
			if next_view.viewInMotion then next_view:viewInMotion( false ) end
			if next_view.viewIsVisible then next_view:viewIsVisible( true ) end

			step_3()
		end

		-- perform transition
		local s2_b = function()
			local p = {
				time=time,
				onComplete=s2_c
			}
			if direction == Navigator.FORWARD then
				p.x = -W
				transition.to( self.display, p )
			else
				p.x = 0
				transition.to( self.display, p )
			end
		end

		local s2_a = function()
			if prev_view.viewInMotion then prev_view:viewInMotion( true ) end
			if prev_view.viewIsVisible then prev_view:viewIsVisible( true ) end
			if next_view.viewInMotion then next_view:viewInMotion( true ) end
			if next_view.viewIsVisible then next_view:viewIsVisible( false ) end
			s2_b()
		end

		s2_a()
	end

	-- setup next view
	local step_1 = function()

		next_view.isVisible = true

		if direction == Navigator.FORWARD then
			self.display.x, self.display.y = 0, 0
			prev_view.x, prev_view.y = H_CENTER, 0
			next_view.x, next_view.y = W+H_CENTER, 0

		else
			self.display.x, self.display.y = -W, 0
			prev_view.x, prev_view.y = W+H_CENTER, 0
			next_view.x, next_view.y = H_CENTER, 0

		end

		step_2()
	end

	step_1()
end




--====================================================================--
--== Event Handlers




return Navigator
