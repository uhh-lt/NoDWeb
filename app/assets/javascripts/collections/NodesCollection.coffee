define ['backbone', 'underscore', 'models/NodeModel'], (Backbone, _, NodeModel) ->
	Backbone.Collection.extend
		model: NodeModel
		groupsCollection: new Backbone.Collection()
		allowedNodesInUnfoldGroups: 19
		
		initialize: () ->
			this.visibleCollection = new Backbone.Collection()
			this.toplabels = new Backbone.Collection()
			this.groupsCollection.on 'change:expanded', _.debounce(() =>
				this.buildVisibleCollection()
				this.trigger('update')
			, 30)
		
		#Parse the json response
		setByData: (data, groups, unfold) ->
			this.groupsCollection.reset()
			this.toplabels.reset()
		
			#use only the nodes with a zoom level of 0
			idx = 0
			relevantNodes = _.filter data, (node) ->
				if node.zoom is 0
					node.idx = idx
					idx++;
					true
				else
					false
				
			this.reset relevantNodes
					
			#Read top labels for cluster
			groups.forEach (group) =>
				id = _.keys(group).shift()
				labels = []
				
				this.toplabels.add {
					id: id,
					labels: new Backbone.Collection( group[id].map (nodeid) => this.get(nodeid) )
				}
			
			this.groupsCollection.reset()
			#this.buildVisibleCollection()
			
			#remove groups from unfold list if they contain more than #allowedNodesInUnfoldGroups nodes
			if unfold?
				unfold = _.filter unfold, (groupId) =>
					(this.where({group: groupId}).length) <= this.allowedNodesInUnfoldGroups
			
			#Workaround for chrome: do not unfold clusters
			if /Chrome/.test(navigator.userAgent) && /Google Inc/.test(navigator.vendor)
				this.unfoldAfterRender = unfold
				this.buildVisibleCollection()
			else
				this.buildVisibleCollection(unfold)
			
		#get visible nodes
		visible: () ->
			this.visibleCollection
			
		groups: () ->
			this.groupsCollection			
		
		buildVisibleCollection: (unfold) ->		
			#Add new nodes to the end of the visible collection			
			this.visibleCollection.reset()
			idx = 0
			uninitializedGroups = {}
			
			this.each (model) =>
				if _.isUndefined( this.groupsCollection.get( model.get( 'group' )) )
					this.groupsCollection.add
						id: model.get('group')
						expanded: if unfold? and _.indexOf(unfold, model.get('group')) >= 0 then true else false
						labels: this.toplabels.get( model.get('group') ).get('labels')
						nodes: []
					
				group = this.groupsCollection.get( model.get( 'group' ) )
				
				show = false
				model.set('neighbours', [])
				
				if group.get('expanded')
					model.set('expanded', true)
					show = true
					
					if !group.get('initialized')? || !group.get('initialized')					
						model.set('x', group.get('x'))
						model.set('y', group.get('y'))
						
						uninitializedGroups[group.get('id')] = group
						group.get( 'nodes' ).push model.get('id')
					else
						model.unset 'x'
						model.unset 'y'
				else
					model.set('expanded', false)
					group.set('nodes', [])
					
					if group.has('master-node') && group.get('master-node') == model.get('id')
						show = true
						model.set('cluster-size', 1)
					else if !group.has('master-node')
						show = true
						group.set('master-node', model.get('id'))
						model.set('cluster-size', 1)
					else
						master = this.get( group.get('master-node') )
						master.set('cluster-size', master.get('cluster-size') + 1)
							
				if show && !this.visibleCollection.get( model.get('id') )?
					this.visibleCollection.add( model )
					model.set('linkcount', 0)
					model.set('idx', idx)
					idx++;
					
			for groupid, group of uninitializedGroups
				group.set 'initialized', true
			