define ['backbone', 'underscore', 'models/LinkModel', 'collections/TagsCollection'], (Backbone, _, model, TagsCollection) ->
	Backbone.Collection.extend
		model: model
		url: () -> jsRoutes.controllers.Graphs.clusterGraph(this.date).url
		
		initialize: (data, options) ->
			this.nodesCollection = options.nodesCollection
			this.tagsCollection = new TagsCollection [],
				linksCollection: this
			this.nodesCollection.on 'update', () => this.update()
		
		#Set date and fetch data
		setDate: (d) -> 
			this.date = d
			this.tagsCollection.setDate d
			this.fetch
				reset: true
		
		#Parse the json response
		parse: (response, options) ->
			#add the nodes to the nodes collection
			this.nodesCollection.setByData response.nodes, response.groups, response.unfold
			this.response = response.links
			
			this.getRelevantLinks()
		
		update: () ->
			this.reset ( this.getRelevantLinks() )
			
		tags: () ->
			this.tagsCollection
			
		getRelevantLinks: () ->
			links = []
			linkList = {}
		
			_.each this.response, (link) =>
			
				if this.nodesCollection.get(link.source)? && this.nodesCollection.get(link.target)?
					src = this.nodesCollection.visible().get(link.source)
					tgt = this.nodesCollection.visible().get(link.target)
					
					#The node is relevant (zoom level = 0) but the cluster is not expanded
					if !src?
						#Get the group of the node
						group = this.nodesCollection.groups().get( this.nodesCollection.get(link.source).get('group') )
						src = this.nodesCollection.visible().get( group.get('master-node') )
					
					if !tgt?
						#Get the group of the node
						group = this.nodesCollection.groups().get( this.nodesCollection.get(link.target).get('group') )
						tgt = this.nodesCollection.visible().get( group.get('master-node') )
					
					linkKey = Math.min(src.get('id'), tgt.get('id')) + '-' + Math.max(src.get('id'), tgt.get('id'))
					
					if src.get('id') != tgt.get('id') && !linkList[linkKey]?
						linkClone = _.clone(link)
						linkClone.source = src.get('idx')
						linkClone.target = tgt.get('idx')
						linkClone.sourceId = link.source
						linkClone.targetId = link.target
						links.push( linkClone )
						src.get('neighbours').push(tgt.get('id'))
						tgt.get('neighbours').push(src.get('id'))
						linkList[linkKey] = true
						if src.get('linkcount')? then src.set('linkcount', src.get('linkcount') + 1) else src.set('linkcount', 1)
						if tgt.get('linkcount')? then tgt.set('linkcount', tgt.get('linkcount') + 1) else tgt.set('linkcount', 1)
						
			#Find separated clusters
			clusters = []
			
			links.forEach (link) ->
				srcCluster = null
				tgtCluster = null
				
				srcCluster = i for cluster, i in clusters when cluster[link.source]? is true
				tgtCluster = i for cluster, i in clusters when cluster[link.target]? is true
				
				if srcCluster == null and tgtCluster == null
					#If src and tgt aren't contained in any cluster add both to a new cluster
					n = clusters.length
					clusters[n] = {}
					clusters[n][link.source] = true
					clusters[n][link.target] = true
				else if srcCluster == null
					#If tgt is contained in a cluster and src is not then add src to the tgt cluster
					clusters[tgtCluster][link.source] = true
				else if tgtCluster == null
					#If src is contained in a cluster and tgt is not then add tgt to the src cluster
					clusters[srcCluster][link.target] = true
				else if srcCluster != tgtCluster
					#if src and tgt are contained in different clusters then join the clusters
					#copy the keys of the target cluster to the source cluster
					clusters[srcCluster] = _.extend clusters[srcCluster], clusters[tgtCluster]
					#remove the target cluster
					clusters.splice tgtCluster, 1
													
			#Add invisible links between the clusters
			for cluster, clusterIndex in clusters
				do (cluster, clusterIndex) =>
					if clusterIndex != 0
						src = _.keys(clusters[clusterIndex - 1]).shift()
						tgt = _.keys(cluster).shift()

						links.push
							source: parseInt(src)
							target: parseInt(tgt)
							invisible: true
							
			#Find separated nodes
			separatedNodes = this.nodesCollection.visible().filter (node) -> if node.get('linkcount') && node.get('linkcount') > 0 then false else true
			
			separatedNodes.forEach (node) ->
				console.log
					source: _.keys(clusters[0]).shift()
					target: node.get('idx')
					invisible: true
			
				links.push
					source: parseInt(_.keys(clusters[0]).shift())
					target: node.get('idx')
					invisible: true

			links
		
		#Return nodes collection
		nodes: () -> this.nodesCollection