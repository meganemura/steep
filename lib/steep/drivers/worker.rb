module Steep
  module Drivers
    class Worker
      attr_reader :stdout, :stderr, :stdin

      attr_accessor :steepfile_path
      attr_accessor :worker_type
      attr_accessor :worker_name

      include Utils::DriverHelper

      def initialize(stdout:, stderr:, stdin:)
        @stdout = stdout
        @stderr = stderr
        @stdin = stdin
      end

      def run()
        Steep.logger.tagged("#{worker_type}:#{worker_name}") do
          project = load_config()

          loader = Project::FileLoader.new(project: project)
          loader.load_sources([])
          loader.load_signatures()

          reader = LanguageServer::Protocol::Transport::Io::Reader.new(stdin)
          writer = LanguageServer::Protocol::Transport::Io::Writer.new(stdout)

          worker = case worker_type
                   when :code
                     Server::CodeWorker.new(project: project, reader: reader, writer: writer)
                   when :signature
                     Server::SignatureWorker.new(project: project, reader: reader, writer: writer)
                   when :interaction
                     Server::InteractionWorker.new(project: project, reader: reader, writer: writer)
                   else
                     raise "Unknown worker type: #{worker_type}"
                   end

          Steep.logger.info "Starting #{worker_type} worker..."

          worker.run()
        rescue Interrupt
          Steep.logger.info "Shutting down by interrupt..."
        end

        0
      end
    end
  end
end
