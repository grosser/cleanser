module Cleanser
  class << self
    def find_polluter(*files)
      failing = files.pop
      if !files.include?(failing)
        abort "Files have to include the failing file, use the copy helper"
      elsif files.size < 2
        abort "Files have to be more than 2, use the copy helper"
      elsif !success?([failing])
        abort "#{failing} fails when run on it's own"
      elsif success?(files)
        abort "tests pass locally"
      else
        loop do
          a = remove_from(files, files.size / 2, :not => failing)
          b = files - (a - [failing])
          status, files = find_polluter_set([a, b], failing)
          if status == :finished
            puts "Fails when #{files.join(", ")} are run together"
            break
          elsif status == :continue
            next
          else
            abort "unable to isolate failure to 2 files"
          end
        end
      end
    end

    private

    def find_polluter_set(sets, failing)
      sets.each do |set|
        next if set == [failing]
        if !success?(set)
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

    def success?(files)
      command = "bundle exec ruby #{files.map { |f| "-r./#{f.sub(/\.rb$/, "")}" }.join(" ")} -e ''"
      puts "Running: #{command}"
      status = system(command)
      puts "Status: #{status ? "Success" : "Failure"}"
      status
    end
  end
end
