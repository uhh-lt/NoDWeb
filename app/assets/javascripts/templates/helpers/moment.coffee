define 'templates/helpers/moment', ['Handlebars', 'underscore', 'moment'], (Handlebars, _, moment) ->
	hbsmoment = (context, block) ->
		if(context and context.hash)
			block = _.cloneDeep context
			context = undefined
		
		date = moment context
		
		date.lang 'de'
		
		for i, dlocal of block.hash
			if date[i]
				date = date[i]( dlocal )
			else
				console.log 'moment.js does not support "' + i '"'
		
		date
		
	Handlebars.registerHelper 'moment', hbsmoment
	hbsmoment