module LetsEncrypt
  # :nodoc:
  class LoggerProxy
    attr_reader :tags

    def initialize(logger, tags:)
      @logger = logger
      @tags = tags.flatten
    end

    def add_tags(*tags)
      @tags += tags.flatten
      @tags = @tags.uniq
    end

    def tag(logger)
      if logger.respond_to?(:tagged)
        current_tags = tags - logger.formatter.current_tags
        logger.tagged(*current_tags) { yield }
      else
        yield
      end
    end

    %i[debug info warn error fatal unknown].each do |severity|
      define_method(severity) do |message|
        log severity, message
      end
    end

    private

    def log(type, message)
      tag(@logger) { @logger.send type, message }
    end
  end
end
