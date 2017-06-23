###
Based on https://github.com/egermano/twitter-highlights-js
* @author Bruno Germano
* @file twitter-parsing.js
* @dependecies none
###
define 'templates/helpers/highlighttwitter', ['Handlebars'], (Handlebars) ->
	highlighttwitter = (context, options) ->
		toLink = (caption, target, opt) ->
			aux = ""
			if !opt
				l = "<a href='" + target + "'>" + caption + "</a>"
			else
				if opt.nofollow
					aux += " rel='nofollow' "
				if opt.newWindow
					aux += " target='_blank' "
				if opt.className
					aux += " class='" + opt.className + "' "
				
				l = "<a href='" + target + "'" + aux + ">" + caption + "</a>"
	
		ret = options.fn(context)
		
		#Links
		ret = ret.replace(/[A-Za-z]+:\/\/[A-Za-z0-9-_]+\.[A-Za-z0-9-_:%&\?\/.=]+/g, (url) ->
			options = 
				nofollow: true
				newWindow: true
			
			toLink url, url, options
		)
		
		#Username
		ret = ret.replace(/[@]+[A-Za-z0-9-_]+/g, (u) ->
			username = u.replace("@","")
			options = 
				nofollow: true
				newWindow: true
			
			toLink u, "http://twitter.com/" + username, options
		)
		
		#HashTag
		ret = ret.replace(/[#]+[A-Za-z0-9-_]+/g, (t) ->
			tag = t.replace "#", "%23"
			options =
				nofollow:true
				newWindow: true
				
			toLink t, "http://twitter.com/search?q=" + tag + "&src=hash", options
		)
		
		ret
	
	Handlebars.registerHelper 'highlighttwitter', highlighttwitter
	highlighttwitter