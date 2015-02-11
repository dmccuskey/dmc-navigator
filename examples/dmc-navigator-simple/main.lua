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

local createGalleriesView, removeGalleriesView, galleriesView_handler
local createGalleryView, removeGalleryView, galleryView_handler
local createImageView, removeImageView, imageView_handler



--====================================================================--
--== Support Functions


--== Galleries

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
removeGalleriesView = function( o )
	-- print( "removeGalleriesView", o )
	o:removeEventListener( o.EVENT, galleriesView_handler )
	o:removeSelf()
end

galleriesView_handler = function( event )
	-- print( "Main:galleriesView_handler", event.type )
	-- Utils.print( event )
	local gallery_data = event.data
	local o = createGalleryView( gallery_data )
	navigator:pushView( o )
end


--== Gallery

createGalleryView = function( gallery )
	local o = GalleryView:new{
		width=W,
		height=H-nav_bar.HEIGHT,
		data=gallery
	}
	o:addEventListener( o.EVENT, galleryView_handler )
	return o
end
removeGalleryView = function( o )
	-- print( "removeGalleryView", o )
	o:removeEventListener( o.EVENT, galleryView_handler )
	o:removeSelf()
end
galleryView_handler = function( event )
	-- print( "Main:galleryView_handler", event.type )
	-- Utils.print( event )
	local image_data = event.data
	local o = createImageView( image_data )
	navigator:pushView( o )
end


--== Image

createImageView = function( image )
	local o = ImageView:new{
		width=W,
		height=H-nav_bar.HEIGHT,
		data=image
	}
	o:addEventListener( o.EVENT, imageView_handler )
	return o
end
removeImageView = function( o )
	-- print( "removeImageView", o )
	o:removeEventListener( o.EVENT, imageView_handler )
	o:removeSelf()
end
imageView_handler = function( event )
	-- print( "Main:imageView_handler", event.type )
	-- none
end


local function navigatorEvent_handler( event )
	-- print( "Main:navigatorEvent_handler", event.type )
	local nav = event.target
	if event.type == nav.REMOVED_VIEW then
		assert( event.view )
		local view = event.view
		if view:isa( GalleriesView ) then
			removeGalleriesView( view )
		elseif view:isa( GalleryView ) then
			removeGalleryView( view )
		elseif view:isa( ImageView ) then
			removeImageView( view )
		end
	end
end


--====================================================================--
--== Main
--====================================================================--


-- create nav bar

nav_bar = Widgets.newNavBar{
	width=W
}
nav_bar.x, nav_bar.y = H_CENTER, 0

-- create navigator

navigator = Navigator:new{
	width=W,
	height=H-nav_bar.HEIGHT,
	default_reference=display.TopCenterReferencePoint
}
navigator.x, navigator.y = H_CENTER, 0+nav_bar.HEIGHT
navigator:addEventListener( navigator.EVENT, navigatorEvent_handler )

navigator.nav_bar = nav_bar -- set nav bar delegate


-- create root Galleries View, and push

o = createGalleriesView( galleries_data )
navigator:pushView( o )

