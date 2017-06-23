define ['backbone.marionette', 'json2', 'd3', 'jquery', 'views/network/LinksView', 'views/network/NodesView'], (marionette, JSON, d3, $, LinksView, NodesView) ->
	Marionette.LayoutView.extend	
		tagName: 'svg'
		className: 'links'
		template: false
		events :
			'mouseover .linkhandle' : 'linkOver'
			'mouseout .linkhandle' : 'linkOut'
			'click .linkhandle' : 'linkClick'
			'mouseover .node': 'nodeOver'
			'mouseout .node': 'nodeOut'
		regions:
			linkRegion: 'g.links'
			nodeRegion: 'g.nodes'
			hullRegion: 'g.hulls'
			
		
		initialize: () ->
			#svg elements need a namespaces => set the namespace element here
			this.setElement document.createElementNS('http://www.w3.org/2000/svg', 'svg')
			
			#listen to collection resets and rerender the graph
			this.listenTo this.collection, 'reset', this.render, this
		
		render: () ->
			#Remove all groups of the svg
			d3.select(this.el).selectAll('g').remove()
		
			#Get arrays of the collections models
			this.links = this.collection.toJSON()
			this.nodes = this.collection.nodes().toJSON()
		
			if this.links.length and this.nodes.length
				#Append groups for links, nodes and hulls
				d3.select(this.el).append('g')
					.attr 'class', 'hulls'
			
				d3.select(this.el).append('g')
					.attr 'class', 'links'

				d3.select(this.el).append('g')
					.attr 'class', 'nodes'
				
				#Resize svg
				d3.select(this.el)
					.attr 'width', 1000
					.attr 'height', 800
					
				Marionette.LayoutView.prototype.render.apply(this, arguments)
				
		onRender: () ->
			#Create force
			this.force = d3.layout.force()
				.nodes this.nodes
				.links this.links
				.size [1000, 500]
				.linkDistance (d, i) -> 30
				.linkStrength (l, i) -> 1
				.gravity 0.2	 # gravity+charge tweaked to ensure good 'grouped' view (e.g. green group not smack between blue&orange, ...
				.charge -600	# ... charge is important to turn single-linked groups to the outside
			
			this.nodes = this.collection.nodes().visibile().toJSON();
			this.links = this.collection.links().visibile().toJSON();
			
			#Add LinkView
			this.linksView = new LinksView
				collection: this.links
				links: this.links
				force: this.force
			
			this.linkRegion.show(this.linksView);
			
			#Add NodeView
			this.nodesView = new NodesView
				collection: this.nodes
				nodes: this.nodes
				force: this.force
			
			this.nodeRegion.show(this.nodesView);
		
			#Register tick callback
			this.force.on 'tick', () => this.onTick()
		
			#Start force
			this.force.start()
				
		onTick: () ->
			this.nodesView.onTick()
			this.linksView.onTick()
			#this.elLinks.attr 'd', (d) ->
			#	'M ' + d.source.x + ' ' + d.source.y + ' L ' + d.target.x + ' ' + d.target.y