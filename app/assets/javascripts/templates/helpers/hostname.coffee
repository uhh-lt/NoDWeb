define 'templates/helpers/hostname', ['Handlebars'], (Handlebars) ->
	hostname = (context, options) ->
		match = context.match(/^(?:ftp|https?):\/\/(?:[^@:\/]*@)?([^:\/]+)/)
		if _.isUndefined(match) || _.isNull(match)
			context;
		else
			if context.length > match[0].length
				match[0] + '/...'
			else
				match[0]
	
	Handlebars.registerHelper 'hostname', hostname
	hostname