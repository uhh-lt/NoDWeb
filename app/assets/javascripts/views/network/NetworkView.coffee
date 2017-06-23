define ['backbone.marionette', 'json2', 'd3', 'jquery', 'cola', 'views/network/NavigationView'], (marionette, JSON, d3, $, cola, NavigationView) ->
	Marionette.ItemView.extend	
		tagName: 'div'
		className: ''
		template : null
		width: 1000
		height: 700
		#Border size: null for no border
		border: null
		#SVG Layers
		layer: {}
		#Node and link data
		data: {
			nodes: []
			links: []
			groups: []
		}
		#All renderable objects like nodes, links, labels, ...
		renderables: {}
		#Colors
		fill: d3.scale.category20()
		#Hullcurve generator
		hullcurve: d3.svg.line().interpolate("cardinal-closed").tension(.85)
		#Drag
		drag:
			behavior: null
			offset: {x: 0, y: 0}
			object: null
			active: false
			timeout: null
			start: null
			current: null
		zoom:
			behavior: null,
			scale: 1
			translate: [0, 0]
		moveStepSize: 10
		
		initialize: () ->
			this.listenTo this.collection, 'reset', this.update, this
			this.listenTo this.collection.tags(), 'add', this.updateTags, this
			this.listenTo this.collection.tags(), 'remove', this.updateTags, this
			this.listenTo this.collection.tags(), 'change', this.updateTags, this
			NotD.vent.on 'relationSelected', (relation) => this.handleRelationSelected relation
			NotD.vent.on 'relationUnselected', (relation) => this.handleRelationUnselected relation
		
		showLoading: () ->
			this.$el.html '<span class="loading-nod-text"></span>'
		
		tickThrottled: _.throttle(() ->
			this.tick()
		, 50)
		
		tick: () ->
			this.renderables.nodes.attr "transform", (d) =>			
				if this.border? && this.border != 0
					if(d.x < this.border)
						d.x = this.border;
					else if(d.x > this.width - this.border)
						d.x = this.width - this.border;
									
					if(d.y < this.border)
						d.y = this.border;
					else if(d.y > this.height - this.border)
						d.y = this.height - this.border;
				
				'translate(' + d.x + ',' + d.y + ')'
				
			this.renderables.links.attr 'd', (d) ->
				sx = d.source.x
				sy = d.source.y
				tx = d.target.x
				ty = d.target.y
				x1 = d.target.x
				y1 = d.source.y
				
				if tx != sx && ty != sy
					if sx > tx
						#swap source and target
						ox = sx
						oy = sy
						sx = tx
						sy = ty 
						tx = ox
						ty = oy
					
					cx1 = sx + (tx - sx) * 0.8
					cy1 = sy;
					cx2 = tx;
					cy2 = sy + (ty - sy) * 0.8
					
					['M', sx, sy, 'C', cx1, cy1, cx2, cy2, tx, ty].join(' ')					
				else if sy = ty
					sign = if sy < this.height / 2 then 1 else -1
					y1 = y2 = sy + 0.2 * sign * Math.abs(sx - tx)
					['M', sx, sy, 'C', sx, y1, tx, y2, tx, ty].join(' ')
				else if sx = tx
					sign = if sx < this.width / 2 then 1 else -1
					x1 = x2 = sx + 0.2 * sign * Math.abs(sy - ty)
					['M', sx, sy, 'C', x1, sy, x2, ty, tx, ty].join(' ')
			
			this.renderables.linkhandles.attr 'd', (d) ->
				sx = d.source.x
				sy = d.source.y
				tx = d.target.x
				ty = d.target.y
				x1 = d.target.x
				y1 = d.source.y
				
				if tx != sx && ty != sy
					if sx > tx
						#swap source and target
						ox = sx
						oy = sy
						sx = tx
						sy = ty 
						tx = ox
						ty = oy
					
					cx1 = sx + (tx - sx) * 0.8
					cy1 = sy;
					cx2 = tx;
					cy2 = sy + (ty - sy) * 0.8
					
					['M', sx, sy, 'C', cx1, cy1, cx2, cy2, tx, ty].join(' ')					
				else if sy = ty
					sign = if sy < this.height / 2 then 1 else -1
					y1 = y2 = sy + 0.2 * sign * Math.abs(sx - tx)
					['M', sx, sy, 'C', sx, y1, tx, y2, tx, ty].join(' ')
				else if sx = tx
					sign = if sx < this.width / 2 then 1 else -1
					x1 = x2 = sx + 0.2 * sign * Math.abs(sy - ty)
					['M', sx, sy, 'C', x1, sy, x2, ty, tx, ty].join(' ')
			
			this.renderables.hulls.attr 'd', (d) =>
				#get all nodes in the group
				nodes = d.nodes
				
				hullset = []
				#get the position of all nodes in the group and add 4 points with an offset of 10px to the array
				nodes.forEach (id) =>
					idx = this.nodesMap[id]
					if this.data.nodes[idx]?
						x = this.data.nodes[idx].x
						y = this.data.nodes[idx].y
						
						hullset.push [x - 10, y]
						hullset.push [x + 10, y]
						hullset.push [x, y - 10]
						hullset.push [x, y + 10]
	
				if hullset.length > 0
					this.hullcurve ( d3.geom.hull( hullset ) )
				else
					0
		
		render: () ->
			this.$el.empty()
		
			if !this.collection.nodes().visible().length
				this.$el.html '<div class="no-data-sry"><div class="alert alert-warning"><i class="fa fa-info-circle fa-4x"></i><br /><strong>Keine Daten</strong><br />Für diesen Tag sind leider keine Daten vorhanden.</div></div>'
				false
			else
				this.$el.append('<div id="navigation"></div>');
			
				navigationView = new NavigationView
					el: document.getElementById('navigation')
					
				this.listenTo navigationView, 'pan', (dir) =>
					this.move
						x: if dir == 'e' then this.moveStepSize * -1 else if dir == 'w' then this.moveStepSize else 0
						y: if dir == 'n' then this.moveStepSize else if dir == 's' then this.moveStepSize * -1 else 0
				, this
				
				this.listenTo navigationView, 'zoom', (dir) =>
					this.handleZoom dir
				, this
				
				navigationView.render()
			
				#Add the main elements: svg + icons + layers for nodes, node labels, link handlers, links and tags
				this.svg = d3.select(this.el).append('svg')
					.attr('width', this.width)
					.attr('height', this.height)
					
				#Append icons
				this.defs = this.svg.append('defs');

				_.each this.collection.nodes().models, (node) =>

					this.imageOpt = node.attributes.image
					this.img = if !!this.imageOpt
				  	this.imageOpt
					else if node.attributes.type == 'PERSON'
						'./assets/images/per.svg'
					else
						'./assets/images/org.svg'

					this.defs.append 'pattern'
					.attr 'id', node.id
					.attr 'x', -15
					.attr 'y', -15
					.attr 'patternUnits', 'userSpaceOnUse'
					.attr 'height', 100
					.attr 'width', 100
					.append 'image'
					.attr 'x', 0
					.attr 'y', 0
					.attr 'width', 300
					.attr 'height', 300
					.attr 'transform', 'scale(0.1)'
					.attr 'xlink:href', this.img

				filter = this.defs.append 'filter'
					.attr 'id', 'filterBlur'
				filter.append 'feColorMatrix'
					.attr 'type', 'matrix'
					.attr 'values', '0 0 0 0 0
						0 0 0 0.65 0
						0 0 0 0 0
						0 0 0 1 0'
				filter.append 'feGaussianBlur'
					.attr 'stdDeviation', '2.5'
					.attr 'result', 'coloredBlur'
				filterMerge = filter.append 'feMerge'
				filterMerge.append 'feMergeNode'
					.attr 'in', 'coloredBlur'
				filterMerge.append 'feMergeNode'
					.attr 'in', 'SourceGraphic'
				
				this.layer.container = this.svg.append('g')
				
				this.layer.hulls = this.layer.container.append('g')
					.attr('id', 'network-hulls')
					.attr('class', 'hulls')
				
				this.layer.tags = this.layer.container.append('g')
					.attr('id', 'tags')
					.attr('class', 'tags')
				
				this.layer.linkhandles = this.layer.container.append('g')
					.attr('id', 'network-linkhandles')
					.attr('class', 'link-handles')
				
				this.layer.links = this.layer.container.append('g')
					.attr('id', 'network-links')
					.attr('class', 'links')
				
				this.layer.nodes = this.layer.container.append('g')
					.attr('id', 'network-nodes')
					.attr('class', 'nodes')
				
				#Initialize the main layout
				this.d3cola = cola.d3adaptor().size([this.width, this.height])
				.linkDistance( (link) =>
					src = this.data.nodes[link.source]
					tgt = this.data.nodes[link.target]
					
					srcgroup = this.collection.nodes().groups().get(src.group)
					tgtgroup = this.collection.nodes().groups().get(tgt.group)
					
					if link.invisible? && link.invisible
						150
					else if !srcgroup.get('expanded')
						30 + 5 * src['cluster-size']
					else if src.group != tgt.group
						100
					else
						(src.linkcount + 2) * 7 + (tgt.linkcount + 2) * 7
				)
				.avoidOverlaps(true)
				
				this.enableDrag()
				this.recalculateSize()
				
				this.d3cola.on('tick', _.bind(() ->
					this.tick()
				, this))
				
				true
		
		move: (offset) ->
			this.zoom.translate[0] += offset.x
			this.zoom.translate[1] += offset.y
			
			this.zoom.behavior
				.translate(this.zoom.translate)
				.event(this.svg)
		
		handleZoom: (dir) ->
			console.log dir
			this.zoom.scale += dir * 0.01
			this.zoom.behavior
				.scale(this.zoom.scale)
				.event(this.svg)
		
		enableDrag: () ->
			this.zoom.behavior = d3.behavior.zoom()
				.scaleExtent [0.1, 10]
				.on 'zoom', () =>
					this.zoom.scale = d3.event.scale
					this.zoom.translate = d3.event.translate
					this.layer.container.attr "transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")"
		
			#Draghandler
			this.drag.behavior = d3.behavior.drag()
				.origin () =>
					this.drag.start = null
					if this.drag.object != null
						this.drag.object.fixed = false
						this.d3cola.stop()
						this.drag.object
					else
						this.drag.offset
				.on 'dragstart', () =>
					d3.event.sourceEvent.stopPropagation()
				.on 'drag', () => 
					if this.drag.start == null
						this.drag.start = 
							x: d3.event.x
							y: d3.event.y
					this.drag.current = 
						x: d3.event.x
						y: d3.event.y
				
					if this.drag.object != null
						this.drag.object.x = d3.event.x
						this.drag.object.y = d3.event.y
						this.drag.object.px = d3.event.x
						this.drag.object.py = d3.event.y
						this.tick()
					else
						this.drag.offset.x = d3.event.x
						this.drag.offset.y = d3.event.y
						this.layer.container.attr 'transform', 'translate(' + d3.event.x + ',' + d3.event.y + ')'
				.on 'dragend', () =>
					if this.drag.object != null
						this.drag.object.fixed = true
						this.d3cola.resume()	
						this.drag.object = null
					else
						this.d3cola.resume()
					
					if this.drag.start != null && this.drag.current != null && (Math.abs(this.drag.start.x - this.drag.current.x) > 5 || Math.abs(this.drag.start.y - this.drag.current.y) > 5)
						this.drag.active = true
						this.drag.behavior = window.setTimeout () =>
							this.drag.active = false
						, 300
			
			this.layer.container.call(this.drag.behavior)
			this.svg.call(this.zoom.behavior)
		
		recalculateSize: () ->
			w = window
			d = document
			e = d.documentElement
			g = d.getElementsByTagName('body')[0]
			documentWidth = this.$el.width() || w.innerWidth || e.clientWidth || g.clientWidth
			documentHeight = this.$el.height() || w.innerHeight || e.clientHeight || g.clientHeight
					
			#	border = 100,	//space for labels
			this.width = documentWidth
			this.height = documentHeight
			this.d3cola.size([this.width, this.height])
			this.svg
				.attr 'width', this.width
				.attr 'height', this.height
		
		handleResize: () ->
			this.recalculateSize()
			this.update()
			
		update: _.debounce(() ->
			if !this.$el.children('svg').length
				if !this.render() then return
		
			#Read link and node data of the collections
			this.data.links = this.collection.toJSON()
			nodes = this.collection.nodes().visible().toJSON()
			
			#Merge attributes of existing nodes with the new data
			this.data.nodes = nodes.map (newNode) =>
				if this.nodesMap? && this.nodesMap[newNode.id]?
					idx = this.nodesMap[newNode.id]
					newNode = _.defaults newNode, this.data.nodes[idx]
				else
					newNode
					
			#Create id to index map
			this.nodesMap = {}
			this.nodesMap[node.id] = i for node, i in this.data.nodes
		
			#Groups
			this.data.groups = _.where(this.collection.nodes().groups().toJSON(), {expanded: true})
		
			_.each this.data.nodes, (node) =>
				node.prevx = if node.x? then node.x else this.width / 2
				node.prevy = if node.y? then node.y else this.height / 2
			
			###Store the current node position
			for node, i in this.data.nodes
				this.data.nodes[i].prevx = if this.data.nodes[i].prevx? then this.data.nodes[i].prevx else this.width / 2
				this.data.nodes[i].prevy = if this.data.nodes[i].prevy? then this.data.nodes[i].prevy else this.height / 2
			###
			
				
			#Initialize layout
			this.d3cola
				.nodes(this.data.nodes, (d) -> d.id)
				.links(this.data.links)
				.size([this.width, this.height])
				.start(20, 10, 15)

			this.renderNodes()
			this.renderLabels()
			this.renderLinks()
			this.renderHulls()
			
			#animate transition from the previous node position to the new node position
			this.d3cola.stop()
			
			this.renderables.nodes
				.transition()
				.duration(1000)
				.attrTween 'transformph', (d, i) =>
					d.tx = if d.x? then d.x else 0
					d.ty = if d.y? then d.y else 0
					d.x = d.prevx
					d.y = d.prevy
					
					a_x = d.x
					b_x = d.tx
					a_y = d.y
					b_y = d.ty
					ret = (t) =>
						d.x = (a_x * (1 - t) + b_x * t)
						d.y = (a_y * (1 - t) + b_y * t)
						this.tickThrottled()
						'translate(' + (a_x * (1 - t) + b_x * t) + ',' + (a_y * (1 - t) + b_y * t) + ')'
				.each 'end', () =>
					this.resumeCola()
					
			this.trigger('updated')
			
			#this.tick()
		, 50 )
		
		resumeCola: _.debounce(() ->
			this.tickFreeze = false
			
			#Unfold nodes containing trendy words after the first rendering of the graph. Used as workaround in chrome
			if this.collection.nodes().unfoldAfterRender? and this.collection.nodes().unfoldAfterRender.length > 0
				this.openCluster(this.collection.nodes().unfoldAfterRender.shift()) while this.collection.nodes().unfoldAfterRender.length > 0
				
			this.trigger('resumed')
		, 50)
		
		renderNodes: () ->
			#Add nodes to the nodes layer
			this.renderables.nodes = this.layer.nodes.selectAll('.node')
				.data(this.data.nodes)
					
			this.renderables.nodes.exit().remove()
			this.renderables.nodes.enter()
				.append('g')
				.append('circle')
				
			this.renderables.nodes
				.attr 'class', (d) =>
					classed = ['node']
					classed.push if d.expanded then 'entity' else 'cluster'
					d.neighbours.forEach (neighbour) ->
						classed.push 'neighbour-of-' + neighbour
					classed.push 'node-' + d.id;
					classed.join ' '
				.attr 'id', (d) =>
					if d.expanded
						'entity-' + d.id
					else
						'cluster-' + d.group
				.on 'mousedown', (d) => this.drag.object = d
				.select('circle')
					.attr('r', (d) =>
						if d.expanded
							15
						else
							15 + d['cluster-size']
					)
					.style('fill', (d) =>
						if d.expanded
							'url(#' + d.id + ')'
						else
							this.fill(d.group)
					)
					.on 'click', (node) =>
						if !this.drag.active
							if node.expanded
								NotD.vent.trigger 'nodeSelected', node.id
							else		
								NotD.vent.trigger 'clusterOpen', node.group
					.on 'mouseover', (node, i) =>
						this.handleMouseover node, i
					.on 'mouseout', (node, i) =>
						this.handleMouseout node, i
		
		openCluster: (groupId) -> 
			group = this.collection.nodes().groups().get( groupId )
			if group?
				if !group.get('expanded') or group.get('expanded') == false
					console.log 'open', groupId
					masterId = group.get('master-node')
					node = this.data.nodes[this.collection.nodes().visible().get(masterId).get('idx')]
					group.set(
						'expanded': true
						'x': node.x
						'y': node.y
					)
					
					true
				else
					false
			else
				false
		
		closeCluster: (groupId) ->
			group = this.collection.nodes().groups().get( groupId )
			if group?
				#unselect the currently selected relation if it links to a node in the cluster
					if this.selectedRelation?
						relation = this.collection.get this.selectedRelation
						
						if relation?
							src = relation.get 'sourceId'
							tgt = relation.get 'targetId'
							
							srcNode = this.collection.nodes().get( src )
							tgtNode = this.collection.nodes().get( tgt )
							
							if ( srcNode? and srcNode.get('group') == groupId ) or ( tgtNode? and tgtNode.get('group') == groupId )
								NotD.vent.trigger 'relationUnselected', relation.get('id')
			
				if group.get('expanded')
					#update the model
					group.set
						expanded: false,
						initialized: false
						
					
		centerNode: (nodeId) ->
			node = this.collection.nodes().visible().get nodeId
			if node?
				data = this.data.nodes[node.get 'idx']
				d3.select(this.renderables.nodes[0][node.get 'idx']).select('circle').attr('transform', 'scale(1)')
				
				#data.x and data.y should be centered on the screen
				this.layer.container
					.transition()
					.duration(1000)
					.ease 'cubic-in-out'
					.attr 'transform', 'translate(' + (this.width / 2 - data.x) + ',' + (this.height / 2 - data.y) + ')'
					.each 'end', () =>
						
						this.zoom.translate = [(this.width / 2 - data.x), (this.height / 2 - data.y)]
						this.zoom.scale = 1
						this.zoom.behavior
							.scale(1)
							.translate(this.zoom.translate)
						
						c = d3.select(this.renderables.nodes[0][node.get 'idx']).select('circle')
						
						for i in [0..5]
							c.transition()
							.delay(i * 500)
							.duration(500)
							.ease 'cubic-in-out'
							.attr 'transform', 'scale(' + ((i + 1)%2 + 1) + ')'
		
		renderLabels: () ->
			#Append labels
			this.renderables.nodes[0].forEach (renderablenode, idx) =>
				if this.data.nodes[idx].expanded
					#Entities
					labels = d3.select(renderablenode).selectAll('text').data([this.data.nodes[idx]])
					labels.exit().remove()
					labels.enter().append('text')
					labels.text (d) => d.name
					labels.select('textPath').remove()
				
				else
					#Clusters
					topnodes = this.collection.nodes().groups().get( this.data.nodes[idx].group ).get('labels')
					
					labels = d3.select(renderablenode).selectAll('text').data(topnodes.toJSON())
					labels.exit().remove()
					
					labels.enter().append('text')
					labels.attr 'class', (d, i) => 'label-' + i
						.text (d) => d.name
					
					###
					Circled labels
					labels = d3.select(renderablenode).selectAll('text').data([topnodes.pluck('name').join(' - ')])
					labels.exit().remove()
					
					labels.enter().append('path')
						.attr 'id', (d) =>
							'cluster-element-' + this.data.nodes[idx].group
						.attr 'd', (d) =>
							r = 10 + this.data.nodes[idx]['cluster-size'] + 3
							'M 0 -' + r + ' A' + r + ',' + r + ' 0 0,1 0,' + r + ' A ' + r + ',' + r + ' 0 0,1 0,-' + r
						.attr 'fill', 'none'
						.style('stroke', '#EEEEEE')
						.style('stroke-width', 0)
					
					labels.enter().append('text')
						.append('textPath')
							.attr 'xlink:href', (d) =>
								'#cluster-element-' + this.data.nodes[idx].group
							.text (d) => d
							.attr 'spacing', 'auto'
					###
		
		renderLinks: () ->
			#Add links to the link layer
			this.renderables.links = this.layer.links.selectAll('.link')
				.data(this.data.links)
				
			this.renderables.links.exit().remove()
			this.renderables.links.enter()
				.append('path')
				.attr('d', (d) ->
					'M ' + d.source.x + ' ' + d.source.y + ' L ' + d.target.x + ' ' + d.target.y;
				)
				.style("stroke-width", 1)
				
			this.renderables.links
				.attr 'id', (d) =>
					'rel-' + d.id
				.attr 'class', (d) => 
					classed = ['link', 'links-node-' + d.source.id, 'links-node-' + d.target.id]
					if d.invisible? && d.invisible
						classed.push 'invisible'
					if this.selectedRelation? and d.id == this.selectedRelation
						classed.push 'selected'
					classed.join ' '
				.style 'filter', (d) => 
					if this.selectedRelation? and d.id == this.selectedRelation
						'url(#filterBlur)'
					else
						''
				
			#Add handles to the link handle layer
			this.renderables.linkhandles = this.layer.linkhandles.selectAll('.linkhandle')
				.data(this.data.links)
				
			this.renderables.linkhandles.exit().remove()
			this.renderables.linkhandles.enter()
				.append('path')
				.attr('d', (d) ->
					'M ' + d.source.x + ' ' + d.source.y + ' L ' + d.target.x + ' ' + d.target.y;
				)
				#.style("stroke-width", 5)
				.on 'click', (d) =>
					NotD.vent.trigger 'relationSelected', d.id
				.on 'mouseover', (d, i) =>
					this.handleMouseoverLink(d, i)
				.on 'mouseout', (d, i) =>
					this.handleMouseoutLink(d, i)
			
			this.renderables.linkhandles
				.attr 'class', (d) => 
					classed = ['linkhandle']
					if d.invisible? && d.invisible
						classed.push 'invisible'
					classed.join ' '
				
		renderHulls: () ->
			this.renderables.hulls = this.layer.hulls.selectAll('path')
				.data(this.data.groups)
				
			this.renderables.hulls.exit().remove()
			this.renderables.hulls.enter()
				.append('path')
				.attr('class', 'hull')
				.style('stroke', 'none')
				.on 'click', (d) =>
					NotD.vent.trigger 'clusterClose', d.id
				
			this.renderables.hulls
				.style 'fill', (d) =>
					this.fill d.id
					
		updateTags: _.debounce(() ->
			if this.renderables.tags?
				this.renderables.tags.remove()
			this.renderables.tags = this.layer.tags.selectAll('text')
				.data _.filter this.collection.tags().toJSON(), (tag) ->
					if ( tag.deleted? && tag.deleted ) or !tag.isPrimary? or !tag.isPrimary
						false
					else
						true
				
			this.renderables.tags.enter()
				.append('text')
				.attr('dy', -3)
				.append('textPath')
					.attr('startOffset', '50%')
					.attr 'xlink:href', (d, i) ->
						'#rel-' + d.relationship
					.text (d) ->
						d.label
		, 100)
		
		handleRelationSelected: (relation) ->
			if this.selectedRelation? and this.selectedRelation == relation
				#NotD.vent.trigger 'relationUnselected', relation
			else
				if this.selectedRelation?
					this.handleRelationUnselected this.selectedRelation
				
				this.selectedRelation = relation
				d3.select('#rel-' + relation).attr 'class', () ->
					d3.select(this).attr('class') + ' selected'
				.style 'filter', 'url(#filterBlur)'
					
				$(this.$el).children('svg').animate
					'margin-left': '-270px'
				, 300
		
		handleRelationUnselected: (relation) ->
			if this.selectedRelation? and this.selectedRelation == relation
				this.selectedRelation = null
			
			d3.select('#rel-' + relation).attr 'class', () ->
				_.without(d3.select(this).attr('class').split(' '), 'selected').join(' ')				
			d3.select('#rel-' + relation).style 'filter', ''
			
			this.handleSourceHide()
				
		handleSourceHide: _.debounce(() ->
			if !this.selectedRelation?
				
				$(this.$el).children('svg').animate
					'margin-left': '0px'
				, 300
		, 50)
						
		handleMouseover: (node, i) ->

			d3.select(this.renderables.nodes[0][i]).attr 'class', () ->
				d3.select(this).attr('class') + ' hover'
				
			d3.selectAll('.links-node-' + node.id).attr 'class', () ->
				d3.select(this).attr('class') + ' parent-hover'
				
			d3.selectAll('.node.neighbour-of-' + node.id).attr 'class', () ->
				d3.select(this).attr('class') + ' parent-hover'
			
			this.svg.attr('class', 'hover')
				
		
		handleMouseout: (node, i) ->
			d3.select(this.renderables.nodes[0][i]).attr 'class', (d) ->
				_.without(d3.select(this).attr('class').split(' '), 'hover').join(' ')
					
			d3.selectAll('.links-node-' + node.id).attr 'class', () ->
				_.without(d3.select(this).attr('class').split(' '), 'parent-hover').join(' ')
			
			d3.selectAll('.node.neighbour-of-' + node.id).attr 'class', () ->
				_.without(d3.select(this).attr('class').split(' '), 'parent-hover').join(' ')
			
			this.svg.attr('class', '')
			
		handleMouseoverLink: (link, i) ->
			d3.select(this.renderables.links[0][i]).attr 'class', () ->
				d3.select(this).attr('class') + ' hover'
			
			d3.select('.node-' + link.source.id).attr 'class', () ->
				d3.select(this).attr('class') + ' parent-hover'
			
			d3.select('.node-' + link.target.id).attr 'class', () ->
				d3.select(this).attr('class') + ' parent-hover'
			
		handleMouseoutLink: (link, i) ->
			d3.select(this.renderables.links[0][i]).attr 'class', () ->
				_.without(d3.select(this).attr('class').split(' '), 'hover').join(' ')
			
			d3.select('.node-' + link.source.id).attr 'class', () ->
				_.without(d3.select(this).attr('class').split(' '), 'parent-hover').join(' ')
			
			d3.select('.node-' + link.target.id).attr 'class', () ->
				_.without(d3.select(this).attr('class').split(' '), 'parent-hover').join(' ')
