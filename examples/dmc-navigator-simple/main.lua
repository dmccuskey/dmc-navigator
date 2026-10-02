--====================================================================--
-- Navigator Simple
--
-- browse galleries of images: each page slides in from the right,
-- Back slides it out, and All Galleries goes back to the first page
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014-2026 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--====================================================================--
--== Imports


local Navigator = require 'dmc_corona.dmc_navigator'

local galleries_data = require 'data.gallery'

local ListView = require 'views.list_view'
local ImageView = require 'views.image_view'
local newButton = require 'views.button'



--====================================================================--
--== Setup, Constants


local W, H = display.contentWidth, display.contentHeight
local H_CENTER = W*0.5

local BAR_HEIGHT = 50

display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "background", 0.15, 0.15, 0.18 )

local navigator, title, back_btn -- set later



--====================================================================--
--== Support Functions


-- show the title of the page the navigator is going to,
-- and Back on every page but the first
--
local function updateTitleBar( view, count )
	title.text = view.title
	back_btn.isVisible = ( count>1 )
end


local function pushPage( view )
	navigator:pushView( view )
	-- the first view is on the stack at once, the others when their slide ends
	local views = navigator.views
	updateTitleBar( view, views[#views]==view and #views or #views+1 )
end

local function goBack()
	if navigator:popViewAnimated() then
		local views = navigator.views
		updateTitleBar( views[#views-1], #views-1 )
	end
end

local function goHome()
	if navigator:popToRoot() then
		local views = navigator.views
		updateTitleBar( views[1], 1 )
	end
end


local createGalleryView, createImageView

local function newPage( params )
	params.width, params.height = W, H-BAR_HEIGHT
	return params
end

local function createGalleriesView( galleries )
	local o = ListView:new( newPage{ title="My Galleries", items=galleries } )
	o:addEventListener( o.EVENT, function( event )
		if event.type==o.SELECTED then pushPage( createGalleryView( event.data ) ) end
	end )
	return o
end

createGalleryView = function( gallery )
	local o = ListView:new( newPage{ title=gallery.name, items=gallery.images } )
	o:addEventListener( o.EVENT, function( event )
		if event.type==o.SELECTED then pushPage( createImageView( event.data ) ) end
	end )
	return o
end

createImageView = function( image )
	local o = ImageView:new( newPage{ image=image } )
	o:addEventListener( o.EVENT, function( event )
		if event.type==o.HOME then goHome() end
	end )
	return o
end


-- the navigator is done with a view once it has slid out
--
local function navigatorEvent_handler( event )
	local nav = event.target
	if event.type == nav.REMOVED_VIEW then
		event.view:removeSelf()
	end
end



--====================================================================--
--== Main
--====================================================================--


-- title bar

local o = display.newRect( H_CENTER, 0, W, BAR_HEIGHT )
o:setFillColor( 0.25, 0.25, 0.3 )
o.anchorY = 0

title = display.newText{ text="", x=H_CENTER, y=BAR_HEIGHT*0.5, fontSize=20 }

back_btn = newButton{ label="Back", width=70, height=34, onRelease=goBack }
back_btn.x, back_btn.y = 45, BAR_HEIGHT*0.5

-- navigator, below the title bar; it places its views by their top center

navigator = Navigator:new{
	width=W,
	height=H-BAR_HEIGHT
}
navigator.x, navigator.y = H_CENTER, BAR_HEIGHT
navigator:addEventListener( navigator.EVENT, navigatorEvent_handler )

-- the first page appears at once

pushPage( createGalleriesView( galleries_data ) )
