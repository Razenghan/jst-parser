require 'pdf-reader'

module JST
	class Parser
		attr_accessor	:debug
		attr_writer		:jst_response, :name, :rank, :educations, :positions, :skills_all,
						:skills_lower, :skills_upper, :skills_vocational, :skills_graduate

		BRANCH_ARMY = 'United States Army'
		BRANCH_NAVY = 'United States Navy'
		BRANCH_AIR = 'United States Air Force'
		BRANCH_MARINES = 'United States Marine Corps'
		BRANCH_COAST = 'United States Coast Guard'
		BRANCH_DOD = 'Department of Defense'

		class BadPDFError < StandardError ; end
		class UnknownPDFParsingError < StandardError ; end

	 	def parse(pdf_file)
	 		unless @debug
	 			@debug = false
	 		end

			unless pdf_file.nil? || pdf_file.size <= 0
				begin
					pdf_reader = PDF::Reader.new(pdf_file)

					# Iterate through each page & concat
					pdf_text = ''
					pdf_reader.pages.each do |page|
						pdf_text += page.text
					end

				 	# Pull out various attributes
					@name ||= pdf_text.match(/Name:(.+)$/)
					@name = @name[@name.length - 1].gsub!(/^\s+/,'') unless @name.nil?

					@rank ||= pdf_text.match(/Rank:(.+)$/)
					@rank = @rank[@rank.length - 1].gsub!(/^\s+/,'') unless @rank.nil?

					@status ||= pdf_text.match(/Status:(.+)$/)
					@status = @status[@status.length - 1].gsub!(/^\s+/,'') unless @status.nil?

					parse_experience(pdf_text)
					create_response()

					return @jst_response
				rescue PDF::Reader::MalformedPDFError
					raise BadPDFError, "Could not parse JST."
				rescue ArgumentError
					raise BadPDFError, "PDF text parsing exception."
				rescue => exc
					raise UnknownPDFParsingError, "#{exc}"
				# rescue PDF::Reader::UnknownGlyphWidthError
				# 	# Waiting for this exception to be commited from the following pull request:
				# 	# https://github.com/yob/pdf-reader/pull/105
				# 	raise UnknownPDFParsingError, "PDF text parsing exception."
				end
			end
	  	end

		private
		def parse_experience(content)
			experience_section_start = /Military Experience/
			experience_section_end = /College Level Test Scores|Other Learning Experiences/
			#experience_regexp = /[A-Z]{2,4}\-.{2,4}\-.{2,4}\s+\d{2}\-\w{3}-\d{4}/
			#experience_regexp = /([A-Z]{2,4}\-.{2,4}\-.{2,4})|(NONE ASSIGNED)\s+\d{2}\-\w{3}-\d{4}/
			experience_regexp = /([A-Z]{2,4}\-.{2,4}\-.{2,4}\s+\d{2}\-\w{3}-\d{4})|(NONE ASSIGNED)\s+\d{2}\-\w{3}-\d{4}/
			experience_date = /(\d{2}\-[A-Z]{3}\-\d{2,4})\D*(\d{2}\-[A-Z]{3}\-\d{4})?/
			skills_lower_regexp = /(.+)\s+(\d)\s+\w{2}\s+L/
			skills_upper_regexp = /(.+)\s+(\d)\s+\w{2}\s+U/
			skills_vocational_regexp = /(.+)\s+(\d)\s+\w{2}\s+V/
			skills_graduate_regexp = /(.+)\s+(\d)\s+\w{2}\s+G/
			ignore_regexp = []
			ignore_regexp.push (/PRIVACY ACT INFORMATION/)
			ignore_regexp.push (/\(\d{1,2}\/\d{1,2}\)\(\d{1,2}\/\d{1,2}\)/)
			ignore_regexp.push (/None|NONE ASSIGNED/)
			ignore_regexp.push (/^(\d|L|U|V|G|SH)$/)
			ignore_regexp.push (/\*\*/)
			ignore_list = nil
			@positions = []
			@skills_all = {}
			@skills_lower = {}
			@skills_upper = {}
			@skills_vocational = {}
			@skills_graduate = {}
			position = {}
			position_branch = ''
			position_date_begin = ''
			position_date_end = ''
			position_title = ''
			position_desc = ''
			inside_experience_section = false
			at_job_title = false
			at_job_desc = false
			content_array = content.split("\n")

		 	content_array.each do |line|
		 		line.strip!
		 		next if line.empty?
				if line.match(experience_section_start)
					# Reached the job experience section.  Begin parsing out.
					inside_experience_section = true
					puts "-- -- -- JOB EXPERIENCE SECTION START -- -- -- " if @debug
					next
				end
				if line.match(experience_section_end)
					puts "-- -- -- JOB EXPERIENCE SECTION END -- -- -- " if @debug

					# Finished last job position.  Appent previous job position.
					if !position_title.empty? && !position_desc.empty?
						puts '-- -- APPENDING PREVIOUS POSITION -- -- ' if @debug

						append_position(position_branch, position_date_begin, position_date_end, position_title, position_desc)
						position_branch = ''
						position_date_begin = ''
						position_date_end = ''
						position_title = ''
						position_desc = ''
					end
					break
				end

				if inside_experience_section
					line.strip!
					if line.match(experience_regexp)
						puts "-- -- NEW EXPERIENCE" if @debug

						# Determine which branch this job title falls under
						position_branch = BRANCH_ARMY if line.match(/AR-/)
						position_branch = BRANCH_AIR if line.match(/AF-/)
						position_branch = BRANCH_NAVY if line.match(/NV-|NEC-|NER-|LDO-|NWO-/)
						position_branch = BRANCH_MARINES if line.match(/MC-|MCE-/)
						position_branch = BRANCH_COAST if line.match(/CG-|CGR-|CGW-/)
						position_branch = BRANCH_DOD if line.match(/DD-/)

						# Determine the service date (dd-MMM-yyyy)
						if date_match = line.match(experience_date)
							position_date_begin = date_match[1] unless date_match[1].nil?
							puts "-- START DATE:  #{position_date_begin}" unless date_match[1].nil?
							position_date_end = date_match[2] unless date_match[2].nil?
							puts "-- END DATE: #{position_date_end}" unless date_match[2].nil?
						end

						# Next line will be the job titles
						at_job_title = true

						# Since we're at the next job position, append the previous job position.
						if !position_title.empty? && !position_desc.empty?
							append_position(position_branch, position_date_begin, position_date_end, position_title, position_desc)
							position_branch = ''
							position_date_begin = ''
							position_date_end = ''
							position_title = ''
							position_desc = ''
						end

						next
					end

					if at_job_title
						puts "-- JOB TITLE: #{line}" if @debug
						at_job_title = false
						position_title = line

						# Next line will be the job description starting point
						puts "-- JOB DESCRIPTION:"
						at_job_desc = true
						next
					end

					if skills_match = line.match(skills_lower_regexp)
						skill_is_lower = true
					elsif skills_match = line.match(skills_upper_regexp)
						skill_is_upper = true
					elsif skills_match = line.match(skills_vocational_regexp)
						skill_is_vocational = true
					elsif skills_match = line.match(skills_graduate_regexp)
						skill_is_graduate = true
					end

					if skill_is_lower || skill_is_upper || skill_is_vocational || skill_is_graduate
						unless skills_match[1].empty?
							# Strip out skill name
							skill_name = skills_match[1].strip!

							puts "-- SKILL: #{skill_name}" if @debug

							# Init skill name key, if none exists
							@skills_all[skill_name] = 0 if @skills_all[skill_name].nil?
							@skills_lower[skill_name] = 0 if @skills_lower[skill_name].nil? && skill_is_lower
							@skills_upper[skill_name] = 0 if @skills_upper[skill_name].nil? && skill_is_upper
							@skills_vocational[skill_name] = 0 if @skills_vocational[skill_name].nil? && skill_is_vocational
							@skills_graduate[skill_name] = 0 if @skills_graduate[skill_name].nil? && skill_is_graduate
							
							# Strip out skill value (in credits).  Add to skills hash
							if !skills_match[1].empty? && is_numeric?(skills_match[2])
								@skills_all[skill_name] = @skills_all[skill_name] + skills_match[2].to_i
								@skills_lower[skill_name] = @skills_lower[skill_name] + skills_match[2].to_i if skill_is_lower
								@skills_upper[skill_name] = @skills_upper[skill_name] + skills_match[2].to_i if skill_is_upper
								@skills_vocational[skill_name] = @skills_vocational[skill_name] + skills_match[2].to_i if skill_is_vocational
								@skills_graduate[skill_name] = @skills_graduate[skill_name] + skills_match[2].to_i if skill_is_graduate
							end

						end
						next
					end

					if at_job_desc
						ignore_line = false
						ignore_regexp.each do |regex|
							if line.match(regex)
								ignore_line = true
								break
							end
						end

						unless ignore_line
							puts "-> #{line}" if @debug
							position_desc += " #{line}"
						end
					end
				end
			end
			# skills.sort_by {|key, value| value}
		end

		def append_position(branch, date_begin, date_end, title, description)
			position = {}
			position[:branch] = branch
			position[:date_begin] = date_begin
			position[:date_end] = date_end
			position[:title] = title
			position[:description] = description.gsub!(/  /," ")
			@positions.push(position)
		end

		def create_response
			@jst_response = {}
			@jst_response[:name] = @name
			@jst_response[:rank] = @rank
			@jst_response[:education] = @educations
			@jst_response[:experience] = @positions
			@jst_response[:skills] = @skills_all
			@jst_response[:skills_lower] = @skills_lower
			@jst_response[:skills_upper] = @skills_upper
			@jst_response[:skills_vocational] = @skills_vocational
			@jst_response[:skills_graduate] = @skills_graduate
		end

		# We'll clean up coursework later....
		# def parse_coursework(content)
		# 	# Define regexp matchers
		# 	coursework_regexp = /\-[0-9]{4}\-[0-9]{4}/
		# 	experience_regexp = /Military Experience/
		# 	ignore_regexp = /\*\* PRIVACY ACT INFORMATION \*\*/

		# 	@coursework = []
		# 	course = ''
		# 	inside_course_content = false
		#  	content_array = content.split("\n")

		#  	content_array.each do |line|
		#  		puts "LINE: #{line}" if @debug
		# 		if line.match(coursework_regexp) || line.match(experience_regexp)
		# 			# At the next course.  Append previous course information
		# 			inside_course_content = true
		# 			@coursework << course unless course.empty?
		# 			course = line
		# 			line.match(experience_regexp) ? break : next
		# 		end
		# 		if inside_course_content
		# 			course += line unless line.match(ignore_regexp)
		# 		end
		# 	end
		# end

		def is_numeric?(obj)
	      true if Float(obj) rescue false
	    end
	end
end