--====================================================================--
-- data/gallery.lua
--
-- the galleries; each image is a colored square
--====================================================================--

local data = {

	{
		name='Summer Trip',
		images = {
			{ name='Beach', color={ 0.95, 0.85, 0.5 } },
			{ name='Sea', color={ 0.2, 0.55, 0.85 } },
		}
	},

	{
		name='Winter Outing',
		images = {
			{ name='Snow', color={ 0.9, 0.95, 1 } },
			{ name='Forest', color={ 0.15, 0.45, 0.25 } },
		}
	}

}

return data
