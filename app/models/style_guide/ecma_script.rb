module StyleGuide
  class EcmaScript < Base
    DEFAULT_CONFIG_FILENAME = "ecmascript.json"

    def file_review(commit_file)
      file = temp_file(commit_file)
      config_file = temp_config_file
      FileReview.new(filename: commit_file.filename) do |file_review|
        output = `eslint #{file.path} -c #{config_file.path} -f compact`
        puts output.inspect
        output.each_line do |violation|
          next unless violation[file.path]
          puts 'building'
          line = commit_file.line_at(violation[/line (\d+)/, 1].to_i)
          reason = violation[/,\s([^,]+)$/, 1]
          file_review.build_violation(line, reason)
        end
        file_review.complete
      end
    ensure
      config_file.close rescue puts $!
      file.close rescue puts $!
    end

    def file_included?(commit_file)
      !excluded_files.any? do |pattern|
        File.fnmatch?(pattern, commit_file.filename)
      end
    end

    private

    def temp_file(commit_file)
      temp_file = Tempfile.new(["file", ".js"])
      temp_file.puts(commit_file.content)
      temp_file.rewind
      temp_file
    end

    def temp_config_file
      temp_file = Tempfile.new(["config", ".json"])
      temp_file.puts(config.to_json)
      temp_file.rewind
      temp_file
    end

    def config
      custom_config = repo_config.for(name)
      if custom_config["predef"].present?
        custom_config["predef"] |= default_config["predef"]
      end
      default_config.merge(custom_config)
    end

    def excluded_files
      repo_config.ignored_javascript_files
    end

    def default_config
      config_file = File.read(default_config_file)
      JSON.parse(config_file)
    end

    def default_config_file
      DefaultConfigFile.new(
        DEFAULT_CONFIG_FILENAME,
        repository_owner_name
      ).path
    end

    def name
      "ecmascript"
    end
  end
end
