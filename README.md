-- Nothing yet.  Stay tuned! --

## Installation

Add this line to your application's Gemfile:

    gem 'jst-parser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jst-parser

## Usage

	The JST::Parser object accepts a PDF of type IO::File, and will return a hash containing the following keys:
	name
	rank
	education
	experience
	skills
	skills_lower
	skills_upper
	skills_vocational
	skills_graduate

## Code Example

	require 'jst'

	your_pdf = File.open('path/to/pdf')
    parsed_document = JST::Parser.parse(your_pdf)

    parsed_document[:name]

    
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
