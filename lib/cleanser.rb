module Cleanser
  class << self
    def cli(argv)
      options = parse_options(argv)
      find_polluter(argv, options) ? 0 : 1
    end

    def find_polluter(files, options={})
      failing = localize_file(files.pop)
      expand_folders(files, failing)
      files.map! { |f| localize_file(f) }

      if !files.include?(failing)
        abort "Files have to include the failing file"
      elsif files.size < 2
        abort "Files have to be more than 2"
      elsif !success?([failing], options)
        abort "#{failing} fails when run on it's own"
      elsif success?(files, options)
        abort "tests pass locally"
      else
        loop do
          a = remove_from(files, files.size / 2, :not => failing)
          b = files - (a - [failing])
          status, files = find_polluter_set([a, b], failing, options)
          if status == :finished
            puts "Fails when #{files.join(", ")} are run together"
            return true
          elsif status == :continue
            next
          else
            abort "unable to isolate failure to 2 files"
          end
        end
      end
    end

    private

    def parse_options(argv)
      require 'optparse'
      options = {}
      OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^ {10}/, "")
          Find polluting test by bisecting your tests.


          Usage:
              cleanser a.rb failing.rb b.rb c.rb failing.rb
              cleanser folder failing.rb

          Options:
        BANNER
        opts.on("-r", "--rspec", "RSpec") { options[:rspec] = true }
        opts.on("-s", "--seed=SEED", "Use seed to run tests") { |seed| options[:seed] = seed }
        opts.on("-h", "--help", "Show this.") { puts opts; exit }
        opts.on("-v", "--version", "Show Version") do
          require 'cleanser/version' unless defined?(Cleanser::VERSION)
          puts Cleanser::VERSION; exit
        end
      end.parse!(argv)
      options
    end

    def expand_folders(files, failing)
      files.map! do |f|
        if File.file?(f)
          f
        elsif f =~ /".+"/
          f.split(/, ?/).map { |f| f.tr('"', '') }
        else
          files_from_folder(f, pattern(failing))
        end
      end.flatten!
    end

    def localize_file(file)
      file.sub(/^#{Regexp.escape(Dir.pwd)}/, "")
    end

    def files_from_folder(folder, pattern)
      nested = "{,/*/**}" # follow one symlink and direct children
      Dir[File.join(folder, nested, pattern)].map{|f|f.gsub("//", "/")}
    end

    def pattern(test)
      base = File.basename(test)
      if base =~ /^test_/
        "#{$&}*"
      elsif base =~ /(_test|_spec)\.rb/
        "*#{$1}.rb"
      else
        "*"
      end
    end

    def find_polluter_set(sets, failing, options)
      sets.each do |set|
        next if set == [failing]
        if !success?(set, options)
          if set.size == 2
            return [:finished, set]
          else
            return [:continue, set]
          end
        end
      end
      return [:failure, []]
    end

    def remove_from(set, x, options)
      set.dup.delete_if { |f| f != options[:not] && (x -= 1) >= 0 }
    end

    def success?(files, options)
      addition = if seed = options[:seed]
        "#{" --" unless options[:rspec]} --seed #{seed}"
      end

      command = if options[:rspec]
        "bundle exec rspec #{files.join(" ")}#{addition}"
      else
        require_list = files.map { |file| file.sub(" ", "\\ ") }.join(" ")
        "bundle exec ruby -e '%w[#{require_list}].each { |f| require %{./\#{f}} }'#{addition}"
      end
      puts "Running: #{command}"
      status = system(command)
      puts "Status: #{status ? "Success" : "Failure"}"
      status
    end
  end
end
