--====================================================================--
-- Navigator Simple
--
-- basic streaming example
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--====================================================================--
--== Imports


local Navigator = require 'dmc_corona.dmc_navigator'
local Utils = require 'dmc_corona.dmc_utils'
local Widgets = require 'dmc_widgets'

--== Components

local galleries_data = require 'data.gallery'

local GalleriesView = require 'views.galleries_view'
local GalleryView = require 'views.gallery_view'
local ImageView = require 'views.image_view'



--====================================================================--
--== Setup, Constants


local W, H = display.contentWidth, display.contentHeight
local H_CENTER, V_CENTER = W*0.5, H*0.5

local navigator, nav_bar -- set later
local o

local createGalleriesView, galleriesView_handler
local createGalleryView, galleryView_handler
local createImageView, imageView_handler



--====================================================================--
--== Support Functions


createGalleriesView = function( galleries )
	-- print( "createGalleriesView", galleries )
	local o = GalleriesView:new{
		width=W,
		height=H-nav_bar.HEIGHT,
		data=galleries
	}
	o:addEventListener( o.EVENT, galleriesView_handler )
	return o
end

galleriesView_handler = function( event )
	print( "Main:galleriesView_handler", event.type )
	Utils.print( event )
	local gallery_data = event.data
	local o = createGalleryView( gallery_data )
	navigator:pushView( o )
end


createGalleryView = function( gallery )
	local o = GalleryView:new{
		width=W,
		height=H-nav_bar.HEIGHT,
		data=gallery
	}
	o:addEventListener( o.EVENT, galleryView_handler )
	return o
end

galleryView_handler = function( event )
	print( "Main:galleryView_handler", event.type )
	local image_data = event.data
	Utils.print( image_data )
	local o = createImageView( image_data )
	navigator:pushView( o )
end


createImageView = function( image )
	local o = ImageView:new{
		width=W,
		height=H-nav_bar.HEIGHT,
		data=image
	}
	o:addEventListener( o.EVENT, imageView_handler )
	return o
end

imageView_handler = function( event )
	-- print( "Main:imageView_handler", event.type )
	-- none
end


--====================================================================--
--== Main
--====================================================================--


--== Create Navigator and Nav Bar

nav_bar = Widgets.newNavBar{
	width=W
}
nav_bar.x, nav_bar.y = H_CENTER, 0


navigator = Navigator:new{
	width=W,
	height=H-nav_bar.HEIGHT,
	default_reference=display.TopCenterReferencePoint
}
-- o:setAnchor( o.TopCenterReferencePoint )
navigator.x, navigator.y = H_CENTER, 0+nav_bar.HEIGHT

navigator.nav_bar = nav_bar


--== Create Root Gallery Page

o = createGalleriesView( galleries_data )
navigator:pushView( o )


-- timer.performWithDelay( 1000, function()
-- 	o = createGalleryView( galleries_data[1] )
-- 	navigator:pushView( o )
-- end)

