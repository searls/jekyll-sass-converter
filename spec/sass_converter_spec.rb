# frozen_string_literal: true

require "spec_helper"

describe(Jekyll::Converters::Sass) do
  let(:site) do
    Jekyll::Site.new(site_configuration)
  end
  let(:content) do
    <<-SASS
// tl;dr some sass
$font-stack: Helvetica, sans-serif
body
  font-family: $font-stack
  font-color: fuschia
SASS
  end
  let(:css_output) do
    <<-CSS
body {\n  font-family: Helvetica, sans-serif;\n  font-color: fuschia; }
CSS
  end
  let(:invalid_content) do
    <<-SASS
font-family: $font-stack;
SASS
  end

  def compressed(content)
    content.gsub(%r!\s+!, "").gsub(%r!;}!, "}") + "\n"
  end

  def converter(overrides = {})
    Jekyll::Converters::Sass.new(site_configuration({ "sass" => overrides }))
  end

  context "matching file extensions" do
    it "does not match .scss files" do
      expect(converter.matches(".scss")).to be_falsey
    end

    it "matches .sass files" do
      expect(converter.matches(".sass")).to be_truthy
    end
  end

  context "converting sass" do
    it "produces CSS" do
      expect(converter.convert(content)).to eql(compressed(css_output))
    end

    it "includes the syntax error line in the syntax error message" do
      error_message = "Error: Invalid CSS after \"f\": expected 1 selector or at-rule, was \"font-family: $font-\"\n        on line 1 of stdin\n>> font-family: $font-stack;\n\n   ^\n"
      expect do
        converter.convert(invalid_content)
      end.to raise_error(Jekyll::Converters::Scss::SyntaxError, error_message)
    end

    it "removes byte order mark from compressed Sass" do
      result = converter({ "style" => :compressed }).convert("a\n  content: \"\uF015\"")
      expect(result).to eql("a{content:\"\uF015\"}\n")
      expect(result.bytes.to_a[0..2]).not_to eql([0xEF, 0xBB, 0xBF])
    end

    it "does not include the charset if asked not to" do
      result = converter({ "style" => :compressed, "add_charset" => true }).convert("a\n  content: \"\uF015\"")
      expect(result).to eql("@charset \"UTF-8\";a{content:\"\uF015\"}\n")
      expect(result.bytes.to_a[0..2]).not_to eql([0xEF, 0xBB, 0xBF])
    end
  end
end
