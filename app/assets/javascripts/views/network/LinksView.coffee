define ['backbone.marionette', 'json2', 'd3', 'jquery'], (marionette, JSON, d3, $) ->
	Marionette.ItemView.extend	
		tagName: 'g'
		className: ''
				
		initialize: (options) ->
			#svg elements need a namespaces => set the namespaced element here
			this.setElement document.createElementNS('http://www.w3.org/2000/svg', 'g')
			
			this.links = options.links
			this.force = options.force
		
		render: () ->
			this.elLinks = d3.select(this.el).selectAll("path.link").data(this.links)
			this.elLinks.exit().remove()
			this.elLinks.enter()
				.append "svg:path"
				.attr "class", "link"
				.style "stroke-width", (d) -> d.size || 1
				
		onTick: () ->
			this.elLinks.attr 'd', (d) ->
				'M ' + d.source.x + ' ' + d.source.y + ' L ' + d.target.x + ' ' + d.target.y