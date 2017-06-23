define ['backbone.marionette', 'json2', 'd3', 'jquery'], (marionette, JSON, d3, $) ->
	Marionette.ItemView.extend	
		tagName: 'g'
		className: ''
				
		initialize: (options) ->
			#svg elements need a namespaces => set the namespaced element here
			this.setElement document.createElementNS('http://www.w3.org/2000/svg', 'g')
			
			this.nodes = options.nodes
			this.force = options.force
			this.dr = 10
		
		render: () ->
			this.elNodes = d3.select(this.el).selectAll("g.nodes").data(this.nodes)
			this.elNodes.exit().remove()
			this.elNodes.enter()
				.append 'g'
				.attr 'class', 'node'
				.append 'circle'
					.attr "r", (d) => if d.size then d.size + this.dr else this.dr + 1
					.style 'fill', (d) -> '#FF0000'
				
		onTick: () ->
			this.elNodes
				.attr 'transform', (d) -> 'translate(' + d.x + ',' + d.y + ')'