require_relative '../process_logger'
require 'nokogiri'
require_relative 'graph'
require_relative 'visual_graph'

require 'geocoder'

# Class to load graph from various formats. Actually implemented is Graphviz formats. Future is OSM format.
class GraphLoader
	attr_reader :highway_attributes

	# Create an instance, save +filename+ and preset highway attributes
	def initialize(filename, highway_attributes)
		@filename = filename
		@highway_attributes = highway_attributes 
	end

	# Load graph from Graphviz file which was previously constructed from this application, i.e. contains necessary data.
	# File needs to contain 
	# => 1) For node its 'id', 'pos' (containing its re-computed position on graphviz space) and 'comment' containig string with comma separated lat and lon
	# => 2) Edge (instead of source and target nodes) might contains info about 'speed' and 'one_way'
	# => 3) Generaly, graph contains parametr 'bb' containing array withhou bounds of map as minlon, minlat, maxlon, maxlat
	#
	# @return [+Graph+, +VisualGraph+]
	def load_graph_viz()
		ProcessLogger.log("Loading graph from GraphViz file #{@filename}.")
		gv = GraphViz.parse(@filename)

		# aux data structures
		hash_of_vertices = {}
		list_of_edges = []
		hash_of_visual_vertices = {}
		list_of_visual_edges = []		

		# process vertices
		ProcessLogger.log("Processing vertices")
		gv.node_count.times { |node_index|
			node = gv.get_node_at_index(node_index)
			vid = node.id

			v = Vertex.new(vid) unless hash_of_vertices.has_key?(vid)
			ProcessLogger.log("\t Vertex #{vid} loaded")
			hash_of_vertices[vid] = v

			geo_pos = node["comment"].to_s.delete("\"").split(",")
			pos = node["pos"].to_s.delete("\"").split(",")	
			hash_of_visual_vertices[vid] = VisualVertex.new(vid, v, geo_pos[0], geo_pos[1], pos[1], pos[0])
			ProcessLogger.log("\t Visual vertex #{vid} in ")
		}

		# process edges
		gv.edge_count.times { |edge_index|
			link = gv.get_edge_at_index(edge_index)
			vid_from = link.node_one.delete("\"")
			vid_to = link.node_two.delete("\"")
			speed = 50
			one_way = false
			link.each_attribute { |k,v|
				speed = v if k == "speed"
				one_way = true if k == "oneway"
			}
			e = Edge.new(vid_from, vid_to, speed, one_way)
			list_of_edges << e
			list_of_visual_edges << VisualEdge.new(e, hash_of_visual_vertices[vid_from], hash_of_visual_vertices[vid_to])
		}

		# Create Graph instance
		g = Graph.new(hash_of_vertices, list_of_edges)

		# Create VisualGraph instance
		bounds = {}
		bounds[:minlon], bounds[:minlat], bounds[:maxlon], bounds[:maxlat] = gv["bb"].to_s.delete("\"").split(",")
		vg = VisualGraph.new(g, hash_of_visual_vertices, list_of_visual_edges, bounds)

		return g, vg
	end

	# Method to load graph from OSM file and create +Graph+ and +VisualGraph+ instances from +self.filename+
	#
	# @return [+Graph+, +VisualGraph+]
	# UC01, UC02 --> must be given directness
	def load_graph(directed)
		ProcessLogger.log("Starting processing graph from OSM #{@filename}")
		osm_file = File.open(@filename)
		osm_doc = Nokogiri::XML(osm_file)
		
		hash_of_vertices = {}
		hash_of_visual_vertices = {}
		list_of_edges = []
		list_of_visual_edges = []
		
		boundaries = osm_doc.xpath('osm/bounds').first
		bounds = {
			:minlon => boundaries[:minlon],
			:maxlon => boundaries[:maxlon],
			:minlat => boundaries[:minlat],
			:maxlat => boundaries[:maxlat]
		}
		
		ProcessLogger.log("Start of processing vertices")
		osm_doc.root.xpath("way").each do |way|
			way.xpath("tag").each do |tag|
				if tag.attr("k") == "highway" && @highway_attributes.include?(tag.attr("v"))
					vertices_ids = []
					way.xpath("nd").each do |node|
						vortex_id = node.attr("ref")
						vertices_ids << vortex_id
						
						unless hash_of_vertices.has_key?(vortex_id)
							hash_of_vertices[vortex_id] = Vertex.new(vortex_id)
							vortex = osm_doc.xpath('osm/node[@id="' + vortex_id + '"]').first
							hash_of_visual_vertices[vortex_id] = VisualVertex.new(vortex_id, hash_of_vertices[vortex_id],
																																		vortex[:lat], vortex[:lon],vortex[:lat], vortex[:lon])
						end
					end
					
					(vertices_ids.count - 1).times do |i|
						vertex1 = hash_of_visual_vertices[vertices_ids[i]]
						vertex2 = hash_of_visual_vertices[vertices_ids[i + 1]]
						max_speed = way.xpath('tag[@k="maxspeed"]').first
						max_speed ? max_speed[:v] : 50
						
						is_one_way = way.xpath('tag[@k="oneway"]').first
						is_one_way ? true : false
						dist = Geocoder::Calculations.distance_between([vertex1.lat, vertex1.lon], [vertex2.lat, vertex2.lon], :units => :km)

						list_of_edges << Edge.new(vertex1.id, vertex2.id, max_speed, is_one_way, dist)
						#p list_of_edges
						
						if directed
							last_edge = list_of_edges.last
							unless last_edge.one_way
								list_of_edges << Edge.new(vertex2.id, vertex1.id, max_speed, is_one_way, dist)
							end
						end
					end
				end
			end
		end
		
		list_of_edges.each do |edge|
			list_of_visual_edges << VisualEdge.new(edge, hash_of_visual_vertices[edge.v1], hash_of_visual_vertices[edge.v2])
		end

		graph = Graph.new(hash_of_vertices, list_of_edges)
		visual_graph = VisualGraph.new(graph, hash_of_visual_vertices, list_of_visual_edges, bounds, directed)

		return graph, visual_graph
	end

	def biggest_comp
		graph, visual_graph = load_graph(true)

	end

end
