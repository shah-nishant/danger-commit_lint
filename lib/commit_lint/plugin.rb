module Danger
  class DangerCommitLint < Plugin
    NOOP_MESSAGE = 'All checks were disabled, nothing to do.'.freeze

    def check(config = {})
      @config = config

      if all_checks_disabled?
        warn NOOP_MESSAGE
        return
      end

      for message in messages
        for klass in enabled_checkers
          checker = klass.new(message)
          fail klass::MESSAGE if checker.fail?
        end
      end
    end

    private

    def checkers
      [SubjectLengthCheck, SubjectPeriodCheck, EmptyLineCheck]
    end

    def enabled_checkers
      checkers.reject { |klass| disabled_checks.include? klass.type }
    end

    def all_checks_disabled?
      @config[:disable] == :all || disabled_checks.count == 3
    end

    def disabled_checks
      @config[:disable] || []
    end

    def messages
      git.commits.map do |commit|
        (subject, empty_line) = commit.message.split("\n")
        { subject: subject, empty_line: empty_line }
      end
    end

    class SubjectLengthCheck
      MESSAGE = 'Please limit commit subject line to 50 characters.'.freeze

      def self.type
        :subject_length
      end

      def initialize(message)
        @subject = message[:subject]
      end

      def fail?
        @subject.length > 50
      end
    end

    class SubjectPeriodCheck
      MESSAGE = 'Please remove period from end of commit subject line.'.freeze

      def self.type
        :subject_period
      end

      def initialize(message)
        @subject = message[:subject]
      end

      def fail?
        @subject.split('').last == '.'
      end
    end

    class EmptyLineCheck
      MESSAGE = 'Please separate subject from body with newline.'.freeze

      def self.type
        :empty_line
      end

      def initialize(message)
        @empty_line = message[:empty_line]
      end

      def fail?
        @empty_line && !@empty_line.empty?
      end
    end
  end
end
