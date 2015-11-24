var config = {
	'prod': {
 	    'version': 1.0,
 	    'port': 8080
	},
	'devel': {
 	    'version': 1.0,
 	    'port': 8083
	}
};

if(process.env.LINCS_DEVEL){
	module.exports = config.devel;
} else {
	module.exports = config.prod;	
}
