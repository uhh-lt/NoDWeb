define 'templates/helpers/highlight', ['Handlebars'], (Handlebars) ->
	highlight = (context, highlights..., options) ->
		quoteRe = (str) ->
			(str+'').replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1")
	
		ret = options.fn(context);
		for hl in highlights
			tokens = hl.split(' ');
			
			while tokens.length > 0
				re = new RegExp( '(' + quoteRe(tokens.join(' ')) + ')', 'gi' )
				if ret.match re
					ret = ret.replace(re, '<b><mark>$1</mark></b>')
					break;
				else
					tokens.shift()
	
		ret
	
	Handlebars.registerHelper 'highlight', highlight
	highlight