module Git
  class Lib
    alias __branches_all__ branches_all

    def branches_all
      arr = []

      # Add '--sort=--authordate' parameter
      command_lines('branch', ['-a', '--sort=-authordate']).each do |b|
        current = (b[0, 2] == '* ')
        arr << [b.gsub('* ', '').strip, current]
      end
      arr
    end

    private :__branches_all__
  end
end

module Genova
  module Git
    class LocalRepositoryManager
      attr_reader :path

      @@logger = nil

      def self.logger=(logger)
        @@logger = logger
      end

      def initialize(account, repository, branch = Settings.github.default_branch)
        @account = account
        @repository = repository
        @branch = branch
        @@logger = ::Logger.new(STDOUT) if @@logger.nil?

        @path = Rails.root.join('tmp', 'repos', @account, @repository).to_s
      end

      def clone
        return if Dir.exist?("#{@path}/.git")
        uri = "git@github.com:#{@account}/#{@repository}.git"

        FileUtils.mkdir_p(@path) unless Dir.exist?(@path)
        ::Git.clone(uri, '', path: @path)
      end

      def update
        clone

        git = git_client
        git.fetch
        git.clean(force: true, d: true)
        git.checkout(@branch) if git.branch != @branch
        git.reset_hard("origin/#{@branch}")
      end

      def open_deploy_config
        clone

        YAML.load(File.read(Pathname(@path).join('config/deploy.yml'))).deep_symbolize_keys
      end

      def origin_branches
        clone

        branches = []
        git_client.branches.remote.each do |branch|
          next if branch.name.include?('->')
          branches << branch
        end

        branches
      end

      def origin_last_commit_id
        clone

        git = git_client
        git.fetch
        git.log('-remotes=origin').first
      end

      private

      def git_client
        ::Git.open(@path, log: @logger)
      end
    end
  end
end
