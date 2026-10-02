--====================================================================--
-- views/button.lua
--
-- a plain button: a rounded rectangle with a label, calling
-- onRelease( event ) when tapped
--====================================================================--


local function newButton( params )
	assert( params.label and params.onRelease, "newButton: requires label and onRelease" )
	local width, height = params.width or 220, params.height or 50
	--==--
	local group = display.newGroup()

	local bg = display.newRoundedRect( group, 0, 0, width, height, 8 )
	bg:setFillColor( 0.3, 0.3, 0.35 )
	bg.strokeWidth = 2
	bg:setStrokeColor( 0.6, 0.6, 0.65 )

	local text = display.newText{ parent=group, text=params.label, fontSize=18 }
	text:setFillColor( 1, 1, 1 )

	group:addEventListener( 'tap', function( event )
		params.onRelease( event )
		return true
	end )

	return group
end


return newButton
