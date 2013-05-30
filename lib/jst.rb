require 'pdf-reader'

module JST
class Parser
	attr_accessor	:jst_response, :name, :rank, :experiences,
					:skills_all, :skills_lower, :skills_upper, :skills_vocational, :skills_graduate

 	def self.parse(pdf_file)
		unless pdf_file.blank?
			begin
				pdf_reader = PDF::Reader.new(pdf_file.open)

				# pdf-reader splits on newline as a 'page'
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
				throw JST::BadPDFError, "Could not parse JST."
			end
		end
  	end

	private
	def self.parse_experience(content)
		experience_start = /Military Experience/
		experience_end = /College Level Test Scores|Other Learning Experiences/
		#experience_regexp = /[A-Z]{2,4}\-.{2,4}\-.{2,4}\s+\d{2}\-\w{3}-\d{4}/
		#experience_regexp = /([A-Z]{2,4}\-.{2,4}\-.{2,4})|(NONE ASSIGNED)\s+\d{2}\-\w{3}-\d{4}/
		experience_regexp = /([A-Z]{2,4}\-.{2,4}\-.{2,4}\s+\d{2}\-\w{3}-\d{4})|(NONE ASSIGNED)\s+\d{2}\-\w{3}-\d{4}/
		skills_lower_regexp = /(.+)\s+(\d)\s+\w{2}\s+L/
		skills_upper_regexp = /(.+)\s+(\d)\s+\w{2}\s+U/
		skills_vocational_regexp = /(.+)\s+(\d)\s+\w{2}\s+V/
		skills_graduate_regexp = /(.+)\s+(\d)\s+\w{2}\s+G/
		ignore_privacy_regexp = /PRIVACY ACT INFORMATION/
		ignore_date_regexp = /\(\d{1,2}\/\d{1,2}\)\(\d{1,2}\/\d{1,2}\)/
		ignore_misc_regexp = /None|NONE ASSIGNED/

		@positions = {}
		@skills_all = {}
		@skills_lower = {}
		@skills_upper = {}
		@skills_vocational = {}
		@skills_graduate = {}
		position_title = ''
		position_desc = ''
		inside_experience_section = false
		at_job_title = false
		at_job_desc = false
		content_array = content.split("\n")

	 	content_array.each do |line|
	 		line.strip!
	 		next if line.blank?

			if line.match(experience_start)
				# Reached the job experience section.  Begin parsing out.
				inside_experience_section = true
				puts "-- -- -- -- -- -- --  INSIDE EXPERIENCE, PARSING -- -- -- -- -- -- -- "
				next
			end
			if line.match(experience_end)
				puts "-- -- -- -- -- -- --  FINISHED PARSING -- -- -- -- -- -- -- "

				# Finished last job position.  Appent previous job position.
				if !position_title.blank? && !position_desc.blank?
					puts '_-_--__-_-__--_ APPENDING -_--__--_-----_'
					@positions[position_title] = position_desc
					position_title = ''
					position_desc = ''
				end
				break
			end

			if inside_experience_section
				if line.match(experience_regexp)
					puts "~~~~~ NEW EXPERIENCE: #{line}"

					# Next line will be the job title
					at_job_title = true

					# At the next job position.  Append previous job position.
					if !position_title.blank? && !position_desc.blank?
						puts '_-_--__-_-__--_ APPENDING -_--__--_-----_'
						@positions[position_title] = position_desc
						position_title = ''
						position_desc = ''
					end
					next
				end

				if at_job_title
					puts "~~~~~ JOB TITLE: #{line}"
					at_job_title = false
					position_title = line

					# Next line will be the job description starting point
					puts " ())()()()  AT JOB DESC"
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
					unless skills_match[1].blank?
						# Strip out skill name
						skill_name = skills_match[1].strip!

						# Init skill name key, if none exists
						@skills_all[skill_name] = 0 if @skills_all[skill_name].nil?
						@skills_lower[skill_name] = 0 if @skills_lower[skill_name].nil? && skill_is_lower
						@skills_upper[skill_name] = 0 if @skills_upper[skill_name].nil? && skill_is_upper
						@skills_vocational[skill_name] = 0 if @skills_vocational[skill_name].nil? && skill_is_vocational
						@skills_graduate[skill_name] = 0 if @skills_graduate[skill_name].nil? && skill_is_graduate
						
						# Strip out skill value (in credits).  Add to skills hash
						if !skills_match[1].blank? && is_numeric?(skills_match[2])
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
					unless line.match(ignore_privacy_regexp) || line.match(ignore_date_regexp) || line.match(ignore_misc_regexp)
						puts "m: #{line}"
						position_desc += line
					end
				end
			end
		end
		# skills.sort_by {|key, value| value}
	end

	def self.create_response
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
	#  		puts "LINE: #{line}"
	# 		if line.match(coursework_regexp) || line.match(experience_regexp)
	# 			# At the next course.  Append previous course information
	# 			inside_course_content = true
	# 			@coursework << course unless course.blank?
	# 			course = line
	# 			line.match(experience_regexp) ? break : next
	# 		end
	# 		if inside_course_content
	# 			course += line unless line.match(ignore_regexp)
	# 		end
	# 	end
	# end

	def self.is_numeric?(obj)
      true if Float(obj) rescue false
    end
end
end