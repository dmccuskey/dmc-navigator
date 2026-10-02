--====================================================================--
-- views/list_view.lua
--
-- a page with a button for each item; tapping one dispatches
-- ListView.SELECTED with the item as event.data
-- the navigator places its views by their top center
--====================================================================--


--====================================================================--
--== Imports


local Objects = require 'dmc_corona.dmc_objects'
local newButton = require 'views.button'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass
local ComponentBase = Objects.ComponentBase



--====================================================================--
--== List View Class
--====================================================================--


local ListView = newClass( ComponentBase, {name="List View"} )

--== Event Constants

ListView.EVENT = 'list-view-event'

ListView.SELECTED = 'item-selected-event'


--======================================================--
-- Start: Setup DMC Objects

function ListView:__init__( params )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	if self.is_class then return end

	assert( params.width and params.height, "List View: requires dimensions" )
	assert( params.title and params.items, "List View: requires title and items" )

	self._width = params.width
	self._height = params.height
	self._items = params.items

	self.title = params.title -- shown by the title bar
end


function ListView:__createView__()
	self:superCall( '__createView__' )
	--==--
	local W, H = self._width, self._height

	local o = display.newRect( 0, 0, W, H )
	o:setFillColor( 0.15, 0.15, 0.18 )
	o.anchorX, o.anchorY = 0.5, 0
	self:insert( o )

	for i, item in ipairs( self._items ) do
		o = newButton{
			label=item.name,
			onRelease=function()
				self:dispatchEvent( self.SELECTED, item )
			end
		}
		o.x, o.y = 0, 60 + (i-1)*70
		self:insert( o )
	end
end

-- END: Setup DMC Objects
--======================================================--



return ListView
