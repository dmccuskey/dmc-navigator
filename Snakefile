# dmc-navigator

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-navigator"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-navigator",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_navigator.lua"
		],
		"requires": [
			"dmc-corona-boot",
			"DMC-Lua-Library",
			"dmc-objects"
		]
	},
	"examples": {
		"base_dir": "examples",
		"apps": []
	},
	"tests": {
		"files": [],
		"requires": []
	}
}

register( "dmc-navigator", module_config )

