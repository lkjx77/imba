
import 'path' as path

export class SourceMap

	def source
		@source

	def options
		@source

	def initialize source
		@source = source
		@maps = []
		@map = ""
		@js = ""

	def filename
		options:options:filename

	def sourceName
		path.basename(filename)

	def sourcePath
		options:options:filename

	def sourceFiles
		[sourceName]

	def parse
		console.log "PARSE"
		var matcher = /\%\%(\d*)\$(\d*)\%\%/
		var replacer = /^(.*?)\%\%(\d*)\$(\d*)\%\%/
		var lines = options:js.split(/\n/g) # what about js?
		@maps = []
		
		var match
		# split the code in lines. go through each line 
		# go through the code looking for LOC markers
		# remove markers along the way and keep track of
		for line,i in lines
			# could split on these?
			var col = 0
			var caret = 0

			@maps[i] = []
			while line.match(matcher)
				line = line.replace(replacer) do |m,pre,line,col|
					caret = pre:length
					var mapping = [ [parseInt(line),parseInt(col)], [i,caret] ] # source and output
					@maps[i].push(mapping)
					return pre
			lines[i] = line

		@js = lines.join('\n')

		console.log JSON.stringify(@maps)
		console.log @source:js
		options:js = lines.join('\n')
		options:js += "\n//# sourceMappingURL={sourceName.replace(/\.imba$/,'.map')}"
		self

	def generate
		parse

		var lastColumn        = 0
		var lastSourceLine    = 0
		var lastSourceColumn  = 0
		var buffer            = ""

		for line,lineNumber in @maps
			lastColumn = 0

			for map,nr in line
				buffer += ',' unless nr == 0
				var src = map[0]
				var dest = map[1]
				
				buffer += encodeVlq(dest[1] - lastColumn)
				lastColumn = dest[1]
				# add index
				buffer += encodeVlq(0)

				# The starting line in the original source, relative to the previous source line.
				buffer += encodeVlq(src[0] - lastSourceLine)
				lastSourceLine = src[0]
				# The starting column in the original source, relative to the previous column.
				buffer += encodeVlq(src[1] - lastSourceColumn)
				lastSourceColumn = src[1]

			buffer += ";"

		var sourcemap =
			version: 3
			file: sourceName.replace(/\.imba/,'.js') or ''
			sourceRoot: options:sourceRoot or ''
			sources:    sourceFiles
			names:      []
			mappings:   buffer

		options:sourcemap = sourcemap
		
		self

	VLQ_SHIFT = 5
	VLQ_CONTINUATION_BIT = 1 << VLQ_SHIFT
	VLQ_VALUE_MASK = VLQ_CONTINUATION_BIT - 1
	BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	# borrowed from CoffeeScript
	def encodeVlq value
		var answer = ''
		# Least significant bit represents the sign.
		var signBit = value < 0 ? 1 : 0
		var nextChunk
		# The next bits are the actual value.
		var valueToEncode = (Math.abs(value) << 1) + signBit
		# Make sure we encode at least one character, even if valueToEncode is 0.
		while valueToEncode or !answer
			var nextChunk = valueToEncode & VLQ_VALUE_MASK
			valueToEncode = valueToEncode >> VLQ_SHIFT
			if valueToEncode
				nextChunk |= VLQ_CONTINUATION_BIT

			answer += encodeBase64(nextChunk)

		answer

	def encodeBase64 value
		BASE64_CHARS[value] # or throw Error.new("Cannot Base64 encode value: {value}")

		
		